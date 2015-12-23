//
//
// lcl.h -- LibComponentLogging, embedded, Gao7Core/G7
//
//
// Copyright (c) 2008-2013 Arne Harren <ah@0xc0.de>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "lcl_G7.h"
#include <string.h>


// Active log levels, indexed by log component.
_G7lcl_level_narrow_t _G7lcl_component_level[_G7lcl_component_t_count];

// Log component identifiers, indexed by log component.
const char * const _G7lcl_component_identifier[] = {
#   define  _G7lcl_component(_identifier, _header, _name)                        \
    #_identifier,
	G7LCLComponentDefinitions
#   undef   _G7lcl_component
};

// Log component headers, indexed by log component.
const char * const _G7lcl_component_header[] = {
#   define  _G7lcl_component(_identifier, _header, _name)                        \
    _header,
	G7LCLComponentDefinitions
#   undef   _G7lcl_component
};

// Log component names, indexed by log component.
const char * const _G7lcl_component_name[] = {
#   define  _G7lcl_component(_identifier, _header, _name)                        \
    _name,
	G7LCLComponentDefinitions
#   undef   _G7lcl_component
};

// Log level headers, indexed by log level.
const char * const _G7lcl_level_header[] = {
    "-",
    "CRITICAL",
    "ERROR",
    "WARNING",
    "INFO",
    "DEBUG",
    "TRACE"
};
const char * const _G7lcl_level_header_1[] = {
    "-",
    "C",
    "E",
    "W",
    "I",
    "D",
    "T"
};
const char * const _G7lcl_level_header_3[] = {
    "---",
    "CRI",
    "ERR",
    "WRN",
    "INF",
    "DBG",
    "TRC"
};

// Log level names, indexed by log level.
const char * const _G7lcl_level_name[] = {
    "Off",
    "Critical",
    "Error",
    "Warning",
    "Info",
    "Debug",
    "Trace"
};

// Version.
#define __G7lcl_version_to_string( _text) __G7lcl_version_to_string0(_text)
#define __G7lcl_version_to_string0(_text) #_text
const char * const _G7lcl_version = __G7lcl_version_to_string(_G7LCL_VERSION_MAJOR)
                              "." __G7lcl_version_to_string(_G7LCL_VERSION_MINOR)
                              "." __G7lcl_version_to_string(_G7LCL_VERSION_BUILD)
                              ""  _G7LCL_VERSION_SUFFIX;

// Configures the given log level for the given log component.
uint32_t G7lcl_configure_by_component(_G7lcl_component_t component, _G7lcl_level_t level) {
    // unsupported level, clip to last level
    if (level > _G7lcl_level_t_last) {
        level = _G7lcl_level_t_last;
    }
    
    // configure the component
    if (component <= _G7lcl_component_t_last) {
        _G7lcl_component_level[component] = level;
        return 1;
    }
    
    return 0;
}

// Configures the given log level for the given log component(s).
static uint32_t _G7lcl_configure_by_text(uint32_t count, const char * const *texts,
                                       _G7lcl_level_narrow_t *levels, const char *text,
                                       _G7lcl_level_t level) {
    // no text given, quit
    if (text == NULL || text[0] == '\0') {
        return 0;
    }
    
    // unsupported level, clip to last level
    if (level > _G7lcl_level_t_last) {
        level = _G7lcl_level_t_last;
    }
    
    // configure the components
    uint32_t num_configured = 0;
    size_t text_len = strlen(text);
    if (text[text_len-1] == '*') {
        // text ends with '*', wildcard suffix was specified
        text_len--;
        for (uint32_t c = 0; c < count; c++) {
            if (strncmp(text, texts[c], text_len) == 0) {
                levels[c] = level;
                num_configured++;
            }
        }
    } else {
        // no wildcard suffix was specified
        for (uint32_t c = 0; c < count; c++) {
            if (strcmp(text, texts[c]) == 0) {
                levels[c] = level;
                num_configured++;
            }
        }
    }
    return num_configured;
}

// Configures the given log level for the given log component(s) by identifier.
uint32_t G7lcl_configure_by_identifier(const char *identifier, _G7lcl_level_t level) {
    return _G7lcl_configure_by_text(_G7lcl_component_t_count, _G7lcl_component_identifier,
                                  _G7lcl_component_level, identifier, level);
}

// Configures the given log level for the given log component(s) by header.
uint32_t G7lcl_configure_by_header(const char *header, _G7lcl_level_t level) {
    return _G7lcl_configure_by_text(_G7lcl_component_t_count, _G7lcl_component_header,
                                  _G7lcl_component_level, header, level);
}

// Configures the given log level for the given log component(s) by name.
uint32_t G7lcl_configure_by_name(const char *name, _G7lcl_level_t level) {
    return _G7lcl_configure_by_text(_G7lcl_component_t_count, _G7lcl_component_name,
                                  _G7lcl_component_level, name, level);
}

