HOST_SYSTEM = $(shell uname | cut -f 1 -d_)
SYSTEM ?= $(HOST_SYSTEM)
CXX = g++
CPPFLAGS += `pkg-config --cflags protobuf grpc`
CXXFLAGS += -std=c++11
ifeq ($(SYSTEM),Darwin)
LDFLAGS += -L/usr/local/lib `pkg-config --libs protobuf grpc++`\
           -lgrpc++_reflection\
           -ldl
else
LDFLAGS += -L/usr/local/lib `pkg-config --libs protobuf grpc++`\
           -Wl,--no-as-needed -lgrpc++_reflection -Wl,--as-needed\
           -ldl
endif

PROTOC = protoc
GRPC_CPP_PLUGIN = grpc_cpp_plugin
GRPC_CPP_PLUGIN_PATH ?= `which $(GRPC_CPP_PLUGIN)`

PROTOS_PATH = ./protos

PROTO_LIST = $(shell ls -l ./protos | awk '{print $$9}' | cut -d' ' -f 1-)

all: proto_build route_guide_client route_guide_server

route_guide_client: ./build/route_guide.pb.o ./build/route_guide.grpc.pb.o ./build/route_guide_client.o ./build/helper.o
	@$(CXX) $^ $(LDFLAGS) -o $@;\
	echo "$@ build is ok"


route_guide_server: ./build/route_guide.pb.o ./build/route_guide.grpc.pb.o ./build/route_guide_server.o ./build/helper.o
	@$(CXX) $^ $(LDFLAGS) -o $@;\
	echo "$@ build is ok"

./build/%.o:./src/%.cc
	@$(CXX) -o $@ $(CXXFLAGS) $(LDFLAGS) -c $<

proto_build:	
	@for name in $(PROTO_LIST) ; \
    do \
        $(PROTOC) -I $(PROTOS_PATH) --grpc_out=./src --plugin=protoc-gen-grpc=$(GRPC_CPP_PLUGIN_PATH) $$name; \
		$(PROTOC) -I $(PROTOS_PATH) --cpp_out=./src $$name;\
    done; \
	echo "proto file build is ok"

clean:
	@rm -f ./build/*.o ./src/*.pb.cc ./src/*.pb.h route_guide_client route_guide_server;\
	echo "clean is ok"
