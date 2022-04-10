#include <stdio.h>
#include "capi/ANECompat_CApi.h"

int main(int argc, char** argv) {
    if (argc < 2) {
        printf("Usage: %s modelpath [logdir]\n", argv[0]);
        return 1;
    }
    
    return test_ane_compatibility_coreml_model(argv[1], (argc > 2) ? argv[2] : NULL);
}