#import <Foundation/Foundation.h>
#import <IOSurface/IOSurface.h>

NSString* IOSurfaceDescription(IOSurfaceRef surf) {
    uint32_t identifier = IOSurfaceGetID(surf);
    size_t planeCount = IOSurfaceGetPlaneCount(surf);
    size_t height = IOSurfaceGetHeight(surf);
    size_t width = IOSurfaceGetWidth(surf);
    int32_t subsampling = IOSurfaceGetSubsampling(surf);
    size_t bytesPerElement = IOSurfaceGetBytesPerElement(surf);
    size_t bytesPerRow = IOSurfaceGetBytesPerRow(surf);
    size_t elementHeight = IOSurfaceGetElementHeight(surf);
    size_t elementWidth = IOSurfaceGetElementWidth(surf);
    size_t allocSize = IOSurfaceGetAllocSize(surf);
    void* baseAddress = IOSurfaceGetBaseAddress(surf);
    size_t componentCount;

    NSMutableString* desc = [NSMutableString string];
    [desc appendFormat: @"IOSurface<%p> {\n", surf];
    [desc appendFormat: @"\tid: %u\n", identifier];
    [desc appendFormat: @"\tplaneCount: %lu\n", planeCount];
    [desc appendFormat: @"\theight: %lu\n", height];
    [desc appendFormat: @"\twidth: %lu\n", width];
    [desc appendFormat: @"\tsubsampling: %d\n", subsampling];
    [desc appendFormat: @"\tbytesPerElement: %lu\n", bytesPerElement];
    [desc appendFormat: @"\tbytesPerRow: %lu\n", bytesPerRow];
    [desc appendFormat: @"\telementHeight: %lu\n", elementHeight];
    [desc appendFormat: @"\telementWidth: %lu\n", elementWidth];
    [desc appendFormat: @"\tallocSize: %lu\n", allocSize];
    [desc appendFormat: @"\tbufAddress: %p\n", baseAddress];
    for (size_t i = 0; i < planeCount; i++) {
        height = IOSurfaceGetHeightOfPlane(surf, i);
        width = IOSurfaceGetWidthOfPlane(surf, i);
        elementHeight = IOSurfaceGetElementHeightOfPlane(surf, i);
        elementWidth = IOSurfaceGetElementWidthOfPlane(surf, i);
        componentCount = IOSurfaceGetNumberOfComponentsOfPlane(surf, i);
        bytesPerElement = IOSurfaceGetBytesPerElementOfPlane(surf, i);
        bytesPerRow = IOSurfaceGetBytesPerRowOfPlane(surf, i);
        baseAddress = IOSurfaceGetBaseAddressOfPlane(surf, i);

        [desc appendFormat: @"\tplane_%lu:\n", i];
        [desc appendFormat: @"\t\theight: %lu\n", height];
        [desc appendFormat: @"\t\twidth: %lu\n", width];
        [desc appendFormat: @"\t\tbytesPerElement: %lu\n", bytesPerElement];
        [desc appendFormat: @"\t\tbytesPerRow: %lu\n", bytesPerRow];
        [desc appendFormat: @"\t\telementHeight: %lu\n", elementHeight];
        [desc appendFormat: @"\t\telementWidth: %lu\n", elementWidth];
        [desc appendFormat: @"\t\tcomponentCount: %lu\n", componentCount];
        [desc appendFormat: @"\t\tbufAddress: %p\n", baseAddress];
    }
    [desc appendString: @"}\n"];

    return desc;
}