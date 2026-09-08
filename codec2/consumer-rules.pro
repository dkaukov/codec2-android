# JNI resolves these methods by their unmangled Java class and method names.
-keepclasseswithmembernames,includedescriptorclasses class io.github.dkaukov.codec2.Codec2 {
    native <methods>;
}
