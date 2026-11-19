# O núcleo em Rust chama o ChirpBle pelo JNI e é chamado pelos métodos `external`:
# o R8 não vê esse uso, e sem esta regra tiraria ou renomearia os métodos.
-keep class org.psito.chirp.ChirpBle { *; }
