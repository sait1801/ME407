#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

/* ************************************************************************** */
int Nd, Nc, Np;
double TOL;

#define BUFSIZE 512

#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))

// Define maximum number of iterations
#define MAX_ITER 10000

/* ************************************************************************** */
double readInputFile(char *fileName, char *tag)
{
    FILE *fp = fopen(fileName, "r");
    // Error Check
    if (fp == NULL)
    {
        printf("Error opening the input file\n");
    }

    int sk = 0;
    double result;
    char buffer[BUFSIZE], fileTag[BUFSIZE];

    while (fgets(buffer, BUFSIZE, fp) != NULL)
    {
        sscanf(buffer, "%s", fileTag);
        if (strstr(fileTag, tag))
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
void readDataFile(char *fileName, double *data)
{
    FILE *fp = fopen(fileName, "r");
    if (fp == NULL)
    {
        printf("Error opening the input file\n");
    }

    int sk = 0;
    char buffer[BUFSIZE], fileTag[BUFSIZE];

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
void writeDataToFile(char *fileName, double *data, int *Ci)
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
void writeCentroidToFile(char *fileName, double *Cm)
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

/*************************************************************************** */
// Function to calculate Euclidean distance between two points
__device__ double distance(double *a, double *b, int Nd)
{
    double sum = 0.0;
    for (int i = 0; i < Nd; i++)
    {
        double diff = a[i] - b[i];
        sum += diff * diff;
    }
    return sqrt(sum);
}

/*************************************************************************** */
// Function to assign each point to the nearest centroid
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

void assignPoints(double *data, int *Ci, int *Ck, double *Cm, int Np, int Nc, int Nd)
{
    // Reset the number of points in the cluster
    for (int n = 0; n < Nc; n++)
    {
        Ck[n] = 0;
    }

    // Allocate device memory
    double *d_data, *d_Cm;
    int *d_Ci, *d_Ck;
    cudaMalloc((void **)&d_data, Np * Nd * sizeof(double));
    cudaMalloc((void **)&d_Ci, Np * sizeof(int));
    cudaMalloc((void **)&d_Ck, Nc * sizeof(int));
    cudaMalloc((void **)&d_Cm, Nc * Nd * sizeof(double));

    // Copy data to device
    cudaMemcpy(d_data, data, Np * Nd * sizeof(double), cudaMemcpyHostToDevice);
    cudaMemcpy(d_Cm, Cm, Nc * Nd * sizeof(double), cudaMemcpyHostToDevice);
    cudaMemcpy(d_Ck, Ck, Nc * sizeof(int), cudaMemcpyHostToDevice);

    // Launch kernel
    int blockSize = 256;
    int numBlocks = (Np + blockSize - 1) / blockSize;
    assignPointsKernel<<<numBlocks, blockSize>>>(d_data, d_Ci, d_Ck, d_Cm, Np, Nc, Nd);

    // Copy results back to host
    cudaMemcpy(Ci, d_Ci, Np * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(Ck, d_Ck, Nc * sizeof(int), cudaMemcpyDeviceToHost);

    // Free device memory
    cudaFree(d_data);
    cudaFree(d_Ci);
    cudaFree(d_Ck);
    cudaFree(d_Cm);
}

/*************************************************************************** */
// Function to update centroids based on the mean of assigned points

__global__ void initCentroids(double *Cm, double *CmCopy, int Nd)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int cluster = idx / Nd;
    int dim = idx % Nd;

    if (idx < Nc * Nd)
    {
        CmCopy[idx] = Cm[idx];
        Cm[idx] = 0.0;
    }
}

// CUDA kernel for updating centroids based on assigned points
__global__ void updateCentroidsKernel(double *data, int *Ci, double *Cm, int Nd, int Np)
{
    __shared__ double sharedData[256 * 4]; // assuming 256 threads per block and Nd <= 4
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int cluster_index = Ci[idx];
    int tid = threadIdx.x;

    if (idx < Np)
    {
        for (int dim = 0; dim < Nd; dim++)
        {
            sharedData[tid * Nd + dim] = data[idx * Nd + dim];
        }
    }
    else
    {
        for (int dim = 0; dim < Nd; dim++)
        {
            sharedData[tid * Nd + dim] = 0.0;
        }
    }

    __syncthreads();

    // Perform reduction in shared memory
    for (int s = blockDim.x / 2; s > 0; s >>= 1)
    {
        if (tid < s)
        {
            for (int dim = 0; dim < Nd; dim++)
            {
                sharedData[tid * Nd + dim] += sharedData[(tid + s) * Nd + dim];
            }
        }
        __syncthreads();
    }

    // Write the result for this block to global memory
    if (tid == 0)
    {
        for (int dim = 0; dim < Nd; dim++)
        {
            atomicAdd(&Cm[cluster_index * Nd + dim], sharedData[dim]);
        }
    }
}

// CUDA kernel for computing the error and updating Cm
__global__ void computeErrorAndUpdate(double *Cm, double *CmCopy, int *Ck, double *err, int Nd)
{
    __shared__ double maxErr[256]; // assuming 256 threads per block
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int cluster = idx / Nd;
    int dim = idx % Nd;

    if (idx < Nc * Nd)
    {
        Cm[idx] = Cm[idx] / Ck[cluster];
        double localErr = fabs(Cm[idx] - CmCopy[idx]);
        maxErr[threadIdx.x] = localErr;

        __syncthreads();

        // Reduce to find the maximum error within the block
        for (int stride = blockDim.x / 2; stride > 0; stride >>= 1)
        {
            if (threadIdx.x < stride)
            {
                maxErr[threadIdx.x] = fmax(maxErr[threadIdx.x], maxErr[threadIdx.x + stride]);
            }
            __syncthreads();
        }

        // Write the block's maximum error to global memory
        if (threadIdx.x == 0)
        {
            err[blockIdx.x] = maxErr[0];
        }
    }
}

// Host function to update centroids
double updateCentroids(double *data, int *Ci, int *Ck, double *Cm)
{
    double *CmCopy;
    double *d_data, *d_Cm, *d_CmCopy;
    int *d_Ci, *d_Ck;
    double *d_err, h_err = 1.E-12;

    cudaMalloc((void **)&d_data, Np * Nd * sizeof(double));
    cudaMalloc((void **)&d_Ci, Np * sizeof(int));
    cudaMalloc((void **)&d_Ck, Nc * sizeof(int));
    cudaMalloc((void **)&d_Cm, Nc * Nd * sizeof(double));
    cudaMalloc((void **)&d_CmCopy, Nc * Nd * sizeof(double));
    cudaMalloc((void **)&d_err, sizeof(double));

    cudaMemcpy(d_data, data, Np * Nd * sizeof(double), cudaMemcpyHostToDevice);
    cudaMemcpy(d_Ci, Ci, Np * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_Ck, Ck, Nc * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_Cm, Cm, Nc * Nd * sizeof(double), cudaMemcpyHostToDevice);
    cudaMemcpy(d_err, &h_err, sizeof(double), cudaMemcpyHostToDevice);
    int threadsPerBlock = 256;
    int blocksPerGrid = (Nc * Nd + threadsPerBlock - 1) / threadsPerBlock;
    double *d_blockErr;
    cudaMalloc((void **)&d_blockErr, blocksPerGrid * sizeof(double)); // Compute error and update Cm
    // Compute error and update Cm

    // Compute error and update Cm
    computeErrorAndUpdate<<<blocksPerGrid, threadsPerBlock>>>(d_Cm, d_CmCopy, d_Ck, d_blockErr, Nd);

    double *h_blockErr = (double *)malloc(blocksPerGrid * sizeof(double));
    cudaMemcpy(h_blockErr, d_blockErr, blocksPerGrid * sizeof(double), cudaMemcpyDeviceToHost);

    double maxErr = 0.0;
    for (int i = 0; i < blocksPerGrid; i++)
    {
        maxErr = fmax(maxErr, h_blockErr[i]);
    }

    // Initialize Cm and CmCopy
    initCentroids<<<blocksPerGrid, threadsPerBlock>>>(d_Cm, d_CmCopy, Nd);

    blocksPerGrid = (Np + threadsPerBlock - 1) / threadsPerBlock;

    // Update centroids based on assigned points
    updateCentroidsKernel<<<blocksPerGrid, threadsPerBlock>>>(d_data, d_Ci, d_Cm, Nd, Np);

    blocksPerGrid = (Nc * Nd + threadsPerBlock - 1) / threadsPerBlock;

    cudaMemcpy(Cm, d_Cm, Nc * Nd * sizeof(double), cudaMemcpyDeviceToHost);
    cudaMemcpy(&h_err, d_err, sizeof(double), cudaMemcpyDeviceToHost);

    cudaFree(d_data);
    cudaFree(d_Ci);
    cudaFree(d_Ck);
    cudaFree(d_Cm);
    cudaFree(d_CmCopy);
    cudaFree(d_err);

    free(h_blockErr);
    cudaFree(d_blockErr);

    return maxErr;
}
/*************************************************************************** */
// Function to perform k-means clustering

__global__ void initClusters(double *data, int *Ci, int *Ck, double *Cm, int Nd, int Np)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < Nc)
    {
        int ids = idx % Np; // Ensure ids is within the range
        for (int dim = 0; dim < Nd; dim++)
        {
            Cm[idx * Nd + dim] = data[ids * Nd + dim];
        }
        Ck[idx] = 0;
        Ci[ids] = idx;
    }
}

__device__ double atomicMaxNew(double *address, double val)
{
    unsigned long long int *address_as_ull = (unsigned long long int *)address;
    unsigned long long int old = *address_as_ull, assumed;

    do
    {
        assumed = old;
        old = atomicCAS(address_as_ull, assumed,
                        __double_as_longlong(fmax(val, __longlong_as_double(assumed))));
    } while (assumed != old);

    return __longlong_as_double(old);
}

void kMeans(double *data, int *Ci, int *Ck, double *Cm)
{
    double *d_data, *d_Cm;
    int *d_Ci, *d_Ck;
    double err = INFINITY;

    cudaMalloc((void **)&d_data, Np * Nd * sizeof(double));
    cudaMalloc((void **)&d_Ci, Np * sizeof(int));
    cudaMalloc((void **)&d_Ck, Nc * sizeof(int));
    cudaMalloc((void **)&d_Cm, Nc * Nd * sizeof(double));

    cudaMemcpy(d_data, data, Np * Nd * sizeof(double), cudaMemcpyHostToDevice);

    int threadsPerBlock = 256;
    int blocksPerGrid = (Nc + threadsPerBlock - 1) / threadsPerBlock;

    // Initialize clusters randomly
    initClusters<<<blocksPerGrid, threadsPerBlock>>>(d_data, d_Ci, d_Ck, d_Cm, Nd, Np);

    cudaMemcpy(Ci, d_Ci, Np * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(Ck, d_Ck, Nc * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(Cm, d_Cm, Nc * Nd * sizeof(double), cudaMemcpyDeviceToHost);

    int sk = 0;
    while (err > TOL)
    {
        // Assuming assignPoints and updateCentroids are already CUDA parallelized
        assignPoints(d_data, d_Ci, d_Ck, d_Cm, Np, Nc, Nd);
        err = updateCentroids(d_data, d_Ci, d_Ck, d_Cm);
        printf("\r Iteration %d %.12e\n", sk, err);
        sk++;
        fflush(stdout);
    }
    printf("\n");

    cudaFree(d_data);
    cudaFree(d_Ci);
    cudaFree(d_Ck);
    cudaFree(d_Cm);
}
/*************************************************************************** */

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

    // Perform k-means clustering
    kMeans(data, Ci, Ck, Cm);

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