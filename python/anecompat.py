import os 
import tempfile
import ctypes
import ctypes.util
from glob import glob


def _load_ane_compat_dylib():
    def _alternative_dylib_lookup():
        # search local directories first
        repo_root_dir = os.path.dirname(os.path.dirname(__file__))
        local_paths = glob(os.path.join(repo_root_dir, "**", "libANECompat.dylib"))
        if len(local_paths) != 0:
            return local_paths[0]
        
        return None

    dylib_path = ctypes.util.find_library("ANECompat") or _alternative_dylib_lookup()
    
    if dylib_path is not None:
        return ctypes.CDLL(dylib_path)
    else:
        raise ValueError("Cannot find libANECompat.dylib")


ANECompatStatus_Passed       = 0
ANECompatStatus_Partial      = 1
ANECompatStatus_Failed       = 2
ANECompatStatus_ReadError    = 3
ANECompatStatus_CompileError = 4
ANECompatStatus_InputError   = 5
ANECompatStatus_PredictError = 6
ANECompatStatus_OtherError   = 7

libANECompat = _load_ane_compat_dylib()


def test_ane_compatibility_coreml_model(mlmodel_or_path):
    """
    Test mlmodel for compatiblity with AppleNeuralEngine

    Parameters
    ----------
    mlmodel_or_path: str | coremltools.models.MLModel
        Instance of MLModel from coremltools, or path to mlmodel/mlpackage or compiled mlmodelc bundle
    
    Returns
    -------
    status: int
        integer status: 0 - fully compatible, 1 - partially compatible, 2 - not compatible
    """
    mlmodel_path = None
    if isinstance(mlmodel_or_path, str):
        mlmodel_path = mlmodel_or_path
    else:
        try:
            import coremltools as ct
            if isinstance(mlmodel_or_path, ct.models.model.MLModel):
                mlmodel_type = mlmodel_or_path.get_spec().WhichOneof("Type")
                ext = ".mlpackage" if mlmodel_type == "mlProgram" else ".mlmodel"
                mlmodel_path = tempfile.mkdtemp(suffix=ext)
                mlmodel_or_path.save(mlmodel_path)
        except ModuleNotFoundError:
            pass

    if mlmodel_path is None:
        raise ValueError("mlmodel_or_path must be str or coremltools.models.MLModel")

    test_ane_compatibility_native_func = libANECompat.test_ane_compatibility_coreml_model
    test_ane_compatibility_native_func.argtypes = [ctypes.c_char_p, ctypes.c_char_p]
    test_ane_compatibility_native_func.restype = ctypes.c_int

    c_mlmodel_path = ctypes.create_string_buffer(str.encode(mlmodel_path))
    res = test_ane_compatibility_native_func(c_mlmodel_path, None)

    if res in [ANECompatStatus_Passed, ANECompatStatus_Partial, ANECompatStatus_Failed]:
        return res
    elif res == ANECompatStatus_ReadError:
        raise ValueError(f"Unable to read model file at {mlmodel_path}")
    elif res == ANECompatStatus_CompileError:
        raise ValueError("Model compilation failure")
    elif res == ANECompatStatus_InputError:
        raise ValueError("Incompatible input of mlmodel. Only multiarray input is supported.")
    elif res == ANECompatStatus_PredictError:
        raise ValueError("Model prediction failure")
    else:
        raise ValueError("Unexpected error while performing compatibility check")
