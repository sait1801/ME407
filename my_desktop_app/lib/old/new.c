#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <cuda_runtime.h>

/* ************************************************************************** */
int Nd, Nc, Np;
double TOL;

#define BUFSIZE 512

#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))

// Define maximum number of iterations
#define MAX_ITER 10000

/* ************************************************************************** */
__device__ double atomicAddDouble(double *address, double val)
{
    unsigned long long int *address_as_ull = (unsigned long long int *)address;
    unsigned long long int old = *address_as_ull, assumed;
    do
    {
        assumed = old;
        old = atomicCAS(address_as_ull, assumed, __double_as_longlong(val + __longlong_as_double(assumed)));
    } while (assumed != old);
    return __longlong_as_double(old);
}

/* ************************************************************************** */
// CUDA kernel to calculate Euclidean distance between two points
__device__ double distance(double *a, double *b, int Nd)
{
    double sum = 0.0;
    for (int dim = 0; dim < Nd; dim++)
    {
        sum += pow((a[dim] - b[dim]), 2);
    }
    return sqrt(sum);
}

/* ************************************************************************** */
// CUDA kernel to assign each point to the nearest centroid
__global__ void assignPointsKernel(double *data, int *Ci, int *Ck, double *Cm, int Np, int Nc, int Nd)
{
    int p = blockIdx.x * blockDim.x + threadIdx.x;
    if (p < Np)
    {
        double min_distance = INFINITY;
        int cluster_index = 0;

        for (int n = 0; n < Nc; n++)
        {
            double d = distance(&data[p * Nd], &Cm[n * Nd], Nd);
            if (d < min_distance)
            {
                min_distance = d;
                cluster_index = n;
            }
        }

        atomicAdd(&Ck[cluster_index], 1);
        Ci[p] = cluster_index;
    }
}

/* ************************************************************************** */
double readInputFile(const char *fileName, const char *tag)
{
    FILE *fp = fopen(fileName, "r");
    // Error Check
    if (fp == NULL)
    {
        printf("Error opening the input file\n");
    }

    int sk = 0;
    double result;
    char buffer[BUFSIZE];

    while (fgets(buffer, BUFSIZE, fp) != NULL)
    {
        if (strstr(buffer, tag))
        {
            fgets(buffer, BUFSIZE, fp);
            sscanf(buffer, "%lf", &result);
            sk++;
            return result;
        }
    }

    if (sk == 0)
    {
        printf("ERROR! Could not find the tag: [%s] in the file [%s]\n", tag, fileName);
        exit(EXIT_FAILURE);
    }
}

/* ************************************************************************** */
void readDataFile(const char *fileName, double *data)
{
    FILE *fp = fopen(fileName, "r");
    if (fp == NULL)
    {
        printf("Error opening the input file\n");
    }

    int sk = 0;
    char buffer[BUFSIZE];

    int shift = Nd;
    while (fgets(buffer, BUFSIZE, fp) != NULL)
    {
        if (Nd == 2)
            sscanf(buffer, "%lf %lf", &data[sk * shift + 0], &data[sk * shift + 1]);
        if (Nd == 3)
            sscanf(buffer, "%lf %lf %lf", &data[sk * shift + 0], &data[sk * shift + 1], &data[sk * shift + 2]);
        if (Nd == 4)
            sscanf(buffer, "%lf %lf %lf %lf", &data[sk * shift + 0], &data[sk * shift + 1], &data[sk * shift + 2], &data[sk * shift + 3]);
        sk++;
    }
}

/* ************************************************************************** */
void writeDataToFile(const char *fileName, double *data, int *Ci)
{
    FILE *fp = fopen(fileName, "w");
    if (fp == NULL)
    {
        printf("Error opening the output file\n");
    }

    for (int p = 0; p < Np; p++)
    {
        fprintf(fp, "%d %d ", p, Ci[p]);
        for (int dim = 0; dim < Nd; dim++)
        {
            fprintf(fp, "%.4f ", data[p * Nd + dim]);
        }
        fprintf(fp, "\n");
    }
    fclose(fp);
}

/* ************************************************************************** */
void writeCentroidToFile(const char *fileName, double *Cm)
{
    FILE *fp = fopen(fileName, "w");
    if (fp == NULL)
    {
        printf("Error opening the output file\n");
    }

    for (int n = 0; n < Nc; n++)
    {
        for (int dim = 0; dim < Nd; dim++)
        {
            fprintf(fp, "%.4f ", Cm[n * Nd + dim]);
        }
        fprintf(fp, "\n");
    }
    fclose(fp);
}

/* ************************************************************************** */
// CUDA kernel to update centroids based on the mean of assigned points
__global__ void updateCentroidsKernel(double *data, int *Ci, int *Ck, double *Cm, double *CmCopy, int Nc, int Nd, int Np)
{
    int n = blockIdx.x * blockDim.x + threadIdx.x;
    if (n < Nc)
    {
        for (int dim = 0; dim < Nd; dim++)
        {
            CmCopy[n * Nd + dim] = Cm[n * Nd + dim];
            Cm[n * Nd + dim] = 0.0;
        }
    }

    __syncthreads();

    int p = blockIdx.y * blockDim.y + threadIdx.y;
    if (p < Np)
    {
        int cluster_index = Ci[p];

        for (int dim = 0; dim < Nd; dim++)
        {
            atomicAddDouble(&Cm[cluster_index * Nd + dim], data[p * Nd + dim]);
        }
    }

    __syncthreads();

    if (n < Nc)
    {
        for (int dim = 0; dim < Nd; dim++)
        {
            Cm[n * Nd + dim] /= Ck[n];
        }
    }
}

/* ************************************************************************** */
// Function to perform k-means clustering on GPU
void kMeansGPU(double *data, int *Ci, int *Ck, double *Cm)
{
    double *d_data, *d_Cm, *d_CmCopy;
    int *d_Ci, *d_Ck;

    // Allocate device memory
    cudaMalloc((void **)&d_data, Np * Nd * sizeof(double));
    cudaMalloc((void **)&d_Ci, Np * sizeof(int));
    cudaMalloc((void **)&d_Ck, Nc * sizeof(int));
    cudaMalloc((void **)&d_Cm, Nc * Nd * sizeof(double));
    cudaMalloc((void **)&d_CmCopy, Nc * Nd * sizeof(double));

    // Copy data from host to device
    cudaMemcpy(d_data, data, Np * Nd * sizeof(double), cudaMemcpyHostToDevice);
    cudaMemcpy(d_Cm, Cm, Nc * Nd * sizeof(double), cudaMemcpyHostToDevice);

    // Initialize clusters randomly
    for (int n = 0; n < Nc; n++)
    {
        int ids = rand() % Np;
        cudaMemcpy(&d_Cm[n * Nd], &data[ids * Nd], Nd * sizeof(double), cudaMemcpyDeviceToDevice);
        Ck[n] = 0;
        Ci[ids] = n;
    }

    cudaMemcpy(d_Ci, Ci, Np * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_Ck, Ck, Nc * sizeof(int), cudaMemcpyHostToDevice);

    double err = INFINITY;

    int sk = 0;
    while (err > TOL)
    {
        // Assign points to clusters
        assignPointsKernel<<<(Np + 255) / 256, 256>>>(d_data, d_Ci, d_Ck, d_Cm, Np, Nc, Nd);
        cudaDeviceSynchronize();

        // Update centroids
        dim3 blockSize(256, 256);
        dim3 gridSize((Nc + blockSize.x - 1) / blockSize.x, (Np + blockSize.y - 1) / blockSize.y);
        updateCentroidsKernel<<<gridSize, blockSize>>>(d_data, d_Ci, d_Ck, d_Cm, d_CmCopy, Nc, Nd, Np);
        cudaDeviceSynchronize();

        // Calculate error
        double *h_Cm = (double *)malloc(Nc * Nd * sizeof(double));
        cudaMemcpy(h_Cm, d_Cm, Nc * Nd * sizeof(double), cudaMemcpyDeviceToHost);
        err = 1.E-12;
        for (int n = 0; n < Nc; n++)
        {
            for (int dim = 0; dim < Nd; dim++)
            {
                err = MAX(err, fabs(h_Cm[n * Nd + dim] - Cm[n * Nd + dim]));
            }
        }
        free(h_Cm);

        printf("\r Iteration %d %.12e\n", sk, err);
        sk++;
        fflush(stdout);
    }
    printf("\n");

    // Copy results from device to host
    cudaMemcpy(Ci, d_Ci, Np * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(Ck, d_Ck, Nc * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(Cm, d_Cm, Nc * Nd * sizeof(double), cudaMemcpyDeviceToHost);

    // Free device memory
    cudaFree(d_data);
    cudaFree(d_Ci);
    cudaFree(d_Ck);
    cudaFree(d_Cm);
    cudaFree(d_CmCopy);
}

/* ************************************************************************** */

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        printf("Usage: ./kmeans input.dat data.dat\n");
        return -1;
    }

    // Read Number of Data Points
    Np = (int)readInputFile(argv[1], "NUMBER_OF_POINTS");
    // Read Number of clusters
    Nc = (int)readInputFile(argv[1], "NUMBER_OF_CLUSTERS");
    // Read Dimension of Data
    Nd = (int)readInputFile(argv[1], "DATA_DIMENSION");
    // Read Tolerance
    TOL = readInputFile(argv[1], "TOLERANCE");

    // Allocate data [x_i, y_i, z_i, ...]
    double *data = (double *)malloc(Np * Nd * sizeof(double));
    // Cluster id mapping every point to cluster
    int *Ci = (int *)calloc(Np, sizeof(int));
    // Number of data points in every cluster
    int *Ck = (int *)calloc(Nc, sizeof(int));
    // Centroid of every clusters
    double *Cm = (double *)calloc(Nc * Nd, sizeof(double));

    // Fill point data from file
    readDataFile(argv[2], data);

    // Perform k-means clustering on GPU
    kMeansGPU(data, Ci, Ck, Cm);

    // Report Results
    for (int n = 0; n < Nc; n++)
    {
        int Npoints = Ck[n];
        printf("(%d of %d) points are in the cluster %d with centroid( ", Npoints, Np, n);
        for (int dim = 0; dim < Nd; dim++)
        {
            printf("%f ", Cm[n * Nd + dim]);
        }
        printf(") \n");
    }

    writeDataToFile("output.dat", data, Ci);
    writeCentroidToFile("centroids.dat", Cm);

    free(data);
    free(Ci);
    free(Ck);
    free(Cm);

    return 0;
}
