# http://make.mad-scientist.net/papers/advanced-auto-dependency-generation/

BINARY		:= automatic_dependency.exe
BASEDIR		:= .
SRCDIR		:= .
OBJDIR 		:= ./obj
DEPDIR		:= $(OBJDIR)

CFILES		:= $(wildcard $(SRCDIR)/*.c)
CPPFILES		:= $(wildcard $(SRCDIR)/*.cpp)

COBJECTS		:= $(addprefix $(OBJDIR)/, $(notdir $(CFILES:.c=.o)))
CPPOBJECTS	:= $(addprefix $(OBJDIR)/, $(notdir $(CPPFILES:.cpp=.o)))

CC				= gcc
CXX			= g++
LD				= $(CXX)

DEBUG			= -g

# Extra optimizations: -funsafe-loop-optimizations -ftree-loop-linear
OPT			= -O3 -flto -fuse-linker-plugin -floop-nest-optimize					\
					 -faggressive-loop-optimizations -fsched2-use-superblocks		\
					 -fgcse-lm -fgcse-sm -fgcse-las -fgcse-after-reload				\
					 -fbranch-target-load-optimize2 -ftree-loop-distribution			\
					 -ftree-loop-im -ftree-loop-ivcanon -fivopts

MARCH			= -march=native -mtune=native

# GCC6: -Wmisleading-indentation -Wnull-dereference -Wmaybe-null-dereference
WARN			= -pedantic -Wall -Wextra -Wundef -Werror -Wconversion 				\
					 -Wformat=2 -Wstrict-overflow=3 -Winit-self -Wswitch-default	\
					 -Wswitch-enum -Wunsafe-loop-optimizations -Wformat-signedness	\
					 -Wsuggest-attribute=noreturn	-Wsuggest-attribute=format			\
					 -Wsuggest-attribute=pure -Wsuggest-attribute=const				\
					 -Wdouble-promotion -Wunknown-pragmas -Wbad-function-cast 		\
					 -Wconversion -Wcomment -Wfloat-equal -Wimplicit-int  			\
					 -Wpointer-arith -Wredundant-decls -Wreturn-type -Wshadow 		\
					 -Wstrict-prototypes -Wswitch-default -Wtrigraphs					\
					 -Wwrite-strings

SECURE		= -pie -fpie -fstack-protector-all -Wformat-security \
					 -D_FORTIFY_SOURCE=2

STATIC		= -static -static-libgcc -Wl,-Bstatic -lpthread -Wl,-Bdynamic
DEPFLAGS 	= -MT $@ -MMD -MP -MF $(DEPDIR)/$*.temp.d
DEFS			=

# Overwrite with simpler settings.
STATIC 		=
SECURE		=


FLAGS			= $(DEBUG) $(OPT) $(MARCH) $(WARN) $(SECURE)
LDFLAGS		= -Wl,--no-undefined $(FLAGS) # -Wl,-z,now -Wl,-z,relro
CFLAGS		= -std=c11 $(FLAGS) $(DEFS)
CPPFLAGS		= -std=c++14 $(FLAGS) $(DEFS)


COMPILE_C	= $(CC) -c $(DEPFLAGS) $(CFLAGS)
COMPILE_CPP	= $(CXX) -c $(DEPFLAGS) $(CPPFLAGS)
POSTCOMPILE = mv -f $(DEPDIR)/$*.temp.d $(DEPDIR)/$*.d


.PHONY: all mkdirs clean
.SECONDARY:


all: mkdirs $(BINARY)


mkdirs:
		  @if not exist $(subst /,\,$(OBJDIR)/) mkdir $(subst /,\,$(OBJDIR)/)
		  @if not exist $(subst /,\,$(DEPDIR)/) mkdir $(subst /,\,$(DEPDIR)/)


$(BINARY): $(COBJECTS) $(CPPOBJECTS)
		  @echo Linking:  $@
		  @$(LD) $(LDFLAGS) $^ -o $@ $(STATIC)


$(OBJDIR)/%.o: $(SRCDIR)/%.c
		  @echo Compiling: $@
		  @$(COMPILE_C) $< -o $@ $(STATIC)
		  @$(POSTCOMPILE)


$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
		  @echo Compiling: $@
		  @$(COMPILE_CPP) $< -o $@ $(STATIC)
		  @$(POSTCOMPILE)

clean:
		  rm -f $(BINARY) $(wildcard $(OBJDIR)/*.o) $(wildcard $(DEPDIR)/*.d)


$(DEPDIR)/%.d: ;
.PRECIOUS: $(DEPDIR)/%.d


-include $(patsubst %,$(DEPDIR)/%.d,$(basename $(CFILES)))
-include $(patsubst %,$(DEPDIR)/%.d,$(basename $(CPPFILES)))
