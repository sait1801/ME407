import cv2


def image_to_raster(image_path: str):
    # Load the image
    img = cv2.imread(image_path)

    # Convert the image to grayscale
    grayscale_img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # Save the grayscale image
    cv2.imwrite('grayscale_image.jpg', grayscale_img)

    # Display the original and grayscale images
    cv2.imshow('Original Image', img)
    cv2.imshow('Grayscale Image', grayscale_img)

    # Wait for a key press and then terminate all windows
    cv2.waitKey(0)
    cv2.destroyAllWindows()
