import os 
import shutil
import ctypes
import tempfile

ANECompatStatus_Passed       = 0
ANECompatStatus_Partial      = 1
ANECompatStatus_Failed       = 2
ANECompatStatus_ReadError    = 3
ANECompatStatus_InputError   = 4
ANECompatStatus_PredictError = 5
ANECompatStatus_OtherError   = 6

libANETest = os.path.abspath(
    os.path.join(os.path.dirname(os.path.dirname(__file__)), "build", "libANECompat.dylib"))
libANETest = ctypes.CDLL(libANETest)

def test_ane_compatibility_coreml_model(mlmodel_path):
    """
    Test mlmodel for compatiblity with AppleNeuralEngine

    Parameters
    ----------
    mlmodel_path: str
        Path to mlmodel/mlpackage or compiled mlmodelc bundle
    
    Returns
    -------
    status: int
        integer status: 0 - fully compatible, 1 - partially compatible, 2 - not compatible
    """
    
    if not isinstance(mlmodel_path, str):
        raise ValueError("Provided model path must be str")

    test_ane_compatibility_native_func = libANETest.test_ane_compatibility_coreml_model
    test_ane_compatibility_native_func.argtypes = [ctypes.c_char_p, ctypes.c_char_p]
    test_ane_compatibility_native_func.restype = ctypes.c_int

    c_mlmodel_path = ctypes.create_string_buffer(str.encode(mlmodel_path))
    res = test_ane_compatibility_native_func(c_mlmodel_path, None)

    if res in [ANECompatStatus_Passed, ANECompatStatus_Partial, ANECompatStatus_Failed]:
        return res
    elif res == ANECompatStatus_ReadError:
        raise ValueError(f"Unable to read model file at {mlmodel_path}")
    elif res == ANECompatStatus_InputError:
        raise ValueError("Incompatible input of mlmodel. Only multiarray input is supported.")
    elif res == ANECompatStatus_PredictError:
        raise ValueError("Model prediction failure")
    else:
        raise ValueError("Unexpected error while performing compatibility check")
