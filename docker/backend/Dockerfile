# Baut den Dart-Frog-Server als eigenständige AOT-Executable —
# orientiert an der offiziellen Vorlage von `dart_frog build --docker`.

# Stufe 1: Produktions-Bundle erzeugen (entspricht `dart_frog build`)
FROM dart:stable AS bundle
WORKDIR /app
COPY backend/ .
RUN dart pub get
RUN dart pub global activate dart_frog_cli
RUN dart pub global run dart_frog_cli:dart_frog build

# Stufe 2: Bundle AOT-kompilieren
FROM dart:stable AS compile
WORKDIR /app
COPY --from=bundle /app/build .
RUN dart pub get
RUN dart compile exe bin/server.dart -o bin/server

# Stufe 3: Minimales Laufzeit-Image
FROM scratch
COPY --from=compile /runtime/ /
COPY --from=compile /app/bin/server /app/bin/
CMD ["/app/bin/server"]
