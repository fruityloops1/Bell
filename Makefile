#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITPRO)),)
$(error "Please set DEVKITPRO in your environment. export DEVKITPRO=<path to>/devkitpro")
endif

ifeq (, $(shell which clang))
$(error "Clang not found in PATH")
endif

export CC	    :=	clang
export CXX	    :=	clang++
export AS	    :=	clang
export OBJDUMP	:=	llvm-objdump
export LD	    := 	$(DEVKITPRO)/devkitARM/arm-none-eabi/bin/ld

#---------------------------------------------------------------------------------
# TARGET is the name of the output
# GAMEID is the id of the game
# GVER is the version of the game
# BUILD is the directory where object files & intermediate files will be placed
# SOURCES is a list of directories containing source code
# INCLUDES is a list of directories containing header files
#---------------------------------------------------------------------------------
TARGET		   := subsdk1
GAMEID         := 0100152000022000
GVER           := 200
BUILD		   := build$(GVER)
SOURCES		   := source
INCLUDES       := include include/sead
TOTALINCLUDES  := $(DEVKITPRO)/devkitARM/arm-none-eabi/include/ $(DEVKITPRO)/devkitARM/arm-none-eabi/include/c++/11.2.0/ $(DEVKITPRO)/devkitARM/arm-none-eabi/include/c++/11.2.0/arm-none-eabi

#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------
ARCH		:=	--target=armv7l-none-eabihf -mabi=aapcs-linux -mcpu=cortex-a57 -mfpu=crypto-neon-fp-armv8 -mfloat-abi=hard -fPIC
	
CFLAGS		:=	$(ARCH) $(INCLUDE) -nostdlib

CXXFLAGS	:=	$(CFLAGS) -fno-rtti -fno-exceptions -fpermissive -std=gnu++1z

ASFLAGS		:=	$(ARCH)

LDFLAGS		:=	-pie -T $(LINKERSCRIPT) -T $(MAIN_SYMBOLS) -T $(SDK_SYMBOLS)


#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export LINKERSCRIPT	    :=	$(CURDIR)/starlight/application.ld

export MAIN_SYMBOLS	    :=	$(CURDIR)/patches/syms/$(GVER)/main.sym

export SDK_SYMBOLS    	:=	$(CURDIR)/patches/syms/$(GVER)/sdk.sym

export OUTPUT		    :=	$(CURDIR)/$(BUILD)/$(notdir $(CURDIR))$(GVER)

export VPATH	    	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir))

export DEPSDIR	    	:=	$(CURDIR)/$(BUILD)

CFILES			:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES			:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))


export OFILES		:=	$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)

export INCLUDE		:=  $(foreach dir,$(INCLUDES),-I $(CURDIR)/$(dir)) \
					$(foreach dir,$(TOTALINCLUDES),-isystem $(dir)) \
					-I$(CURDIR)/$(BUILD)


.PHONY: $(BUILD)

all: clean $(BUILD) package

#---------------------------------------------------------------------------------
$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	@make --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile
	@python3 starlight/elf2nso.py $(OUTPUT).elf $(OUTPUT)
	@python3 starlight/genPatch.py $(GVER)
 
#---------------------------------------------------------------------------------
clean:
	@rm -fr $(BUILD)

send:
	@[ "${FTPUSER}" ] || ( echo "FTP User not set"; exit 1 )
	@[ "${FTPPASSWORD}" ] || ( echo "FTP Password not set"; exit 1 )
	@[ "${FTPIP}" ] || ( echo "FTP IP not set"; exit 1 )
	@echo Uploading module
	@curl -T $(OUTPUT) -u ${FTPUSER}:${FTPPASSWORD} ftp://$(FTPIP):5000/atmosphere/contents/${GAMEID}/exefs/$(TARGET)
	@echo Uploading patches
	$(foreach file, $(wildcard $(CURDIR)/$(BUILD)/*.ips), @curl -T $(file) -u ${FTPUSER}:${FTPPASSWORD} ftp://$(FTPIP):5000/atmosphere/exefs_patches/$(notdir $(CURDIR))/$(notdir ${file});)

package:
	@rm -fr $(CURDIR)/atmosphere
	@mkdir $(CURDIR)/atmosphere
	@mkdir $(CURDIR)/atmosphere/contents
	@mkdir $(CURDIR)/atmosphere/contents/$(GAMEID)
	@mkdir $(CURDIR)/atmosphere/contents/$(GAMEID)/exefs
	@mkdir $(CURDIR)/atmosphere/exefs_patches
	@mkdir $(CURDIR)/atmosphere/exefs_patches/$(notdir $(CURDIR))
ifneq (,$(wildcard $(CURDIR)/romfs))
	@cp -r $(CURDIR)/romfs $(CURDIR)/atmosphere/contents/$(GAMEID)/romfs
endif

	@cp $(OUTPUT) $(CURDIR)/atmosphere/contents/${GAMEID}/exefs/$(TARGET)
	$(foreach file, $(wildcard $(CURDIR)/$(BUILD)/*.ips), @cp $(file) $(CURDIR)/atmosphere/exefs_patches/$(notdir $(CURDIR))/$(notdir ${file});)
	@zip -r $(BUILD)/package$(GVER).zip $(CURDIR)/atmosphere/
	@rm -fr $(CURDIR)/atmosphere/

#---------------------------------------------------------------------------------
else
 
#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------

$(OUTPUT).sym : $(OUTPUT).elf
	$(OBJDUMP) -t $< > $@
	@echo Symbol map written to $(notdir $@)

#---------------------------------------------------------------------------------
%.elf: $(OFILES)
	@echo Linking $(notdir $@)
	$(LD) $(LDFLAGS) $(OFILES) -o $@

#---------------------------------------------------------------------------------
%.o: %.cpp
	@echo $(notdir $<)
	$(CXX) -MMD -MP -MF $(DEPSDIR)/$*.d $(CXXFLAGS) -c $< -o $@ $(ERROR_FILTER)
	
#---------------------------------------------------------------------------------
%.o: %.c
	@echo $(notdir $<)
	$(CC) -MMD -MP -MF $(DEPSDIR)/$*.d $(CFLAGS) -c $< -o $@ $(ERROR_FILTER)
	
#---------------------------------------------------------------------------------
%.o: %.s
	@echo $(notdir $<)
	$(CC) -MMD -MP -MF $(DEPSDIR)/$*.d -x assembler-with-cpp $(ASFLAGS) -c $< -o $@ $(ERROR_FILTER)

-include $(DEPSDIR)/*.d
 
#---------------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------------
