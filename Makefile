CC := clang
CFLAGS := -I./src -I. -g -Wall -arch arm64 -fobjc-arc
LDFLAGS := -g -undefined dynamic_lookup -F /System/Library/PrivateFrameworks/ -framework Foundation -framework CoreML -framework IOSurface -framework AppleNeuralEngine -arch arm64
LIB_SRC := ${wildcard ./src/*.m ./capi/*.m}
BIN_SRC  := ${wildcard ./bin/*.c}
LIB_OBJS := ${patsubst %.m,build/%.o,${LIB_SRC}}
BIN_OBJS := ${patsubst %.c,build/%.o,${BIN_SRC}}
TARGETS := build/libANECompat.dylib build/anecompat
ifeq ($(PREFIX),)
    PREFIX := /usr/local
endif

all: $(TARGETS)

build/libANECompat.dylib: $(LIB_OBJS)
	mkdir -p ${dir $@}
	$(CC)  $^ $(LDFLAGS) -shared -o $@

build/anecompat: ${LIB_OBJS} ${BIN_OBJS}
	mkdir -p ${dir $@}
	$(CC)  $^ $(LDFLAGS) -o $@

build/%.o: %.m
	mkdir -p ${dir $@}
	$(CC) $(CFLAGS) -c -o $@ $<

build/%.o: %.c
	mkdir -p ${dir $@}
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm $(TARGETS) $(LIB_OBJS) $(BIN_OBJS)

install: $(TARGETS)
	install -d $(DESTDIR)$(PREFIX)/lib/
	install -m 644 build/libANECompat.dylib $(DESTDIR)$(PREFIX)/lib/
	install -d $(DESTDIR)$(PREFIX)/bin/
	install -m 644 build/anecompat $(DESTDIR)$(PREFIX)/bin/