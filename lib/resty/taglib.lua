local ffi          = require "ffi"
local ffi_cdef     = ffi.cdef
local ffi_load     = ffi.load
local ffi_str      = ffi.string
local ffi_gc       = ffi.gc
local type         = type
local setmetatable = setmetatable
local assert       = assert
local rawget       = rawget
local rawset       = rawset
ffi_cdef[[
typedef enum {
  TagLib_File_MPEG,
  TagLib_File_OggVorbis,
  TagLib_File_FLAC,
  TagLib_File_MPC,
  TagLib_File_OggFlac,
  TagLib_File_WavPack,
  TagLib_File_Speex,
  TagLib_File_TrueAudio,
  TagLib_File_MP4,
  TagLib_File_ASF
} TagLib_File_Type;
typedef enum {
  TagLib_ID3v2_Latin1,
  TagLib_ID3v2_UTF16,
  TagLib_ID3v2_UTF16BE,
  TagLib_ID3v2_UTF8
} TagLib_ID3v2_Encoding;
typedef struct { int dummy; } TagLib_File;
typedef struct { int dummy; } TagLib_Tag;
typedef struct { int dummy; } TagLib_AudioProperties;
void taglib_set_strings_unicode(int unicode);
void taglib_set_string_management_enabled(int management);
void taglib_free(void* pointer);
TagLib_File *taglib_file_new(const char *filename);
TagLib_File *taglib_file_new_type(const char *filename, TagLib_File_Type type);
void taglib_file_free(TagLib_File *file);
int taglib_file_is_valid(const TagLib_File *file);
TagLib_Tag *taglib_file_tag(const TagLib_File *file);
const TagLib_AudioProperties *taglib_file_audioproperties(const TagLib_File *file);
int taglib_file_save(TagLib_File *file);
char *taglib_tag_title(const TagLib_Tag *tag);
char *taglib_tag_artist(const TagLib_Tag *tag);
char *taglib_tag_album(const TagLib_Tag *tag);
char *taglib_tag_comment(const TagLib_Tag *tag);
char *taglib_tag_genre(const TagLib_Tag *tag);
unsigned int taglib_tag_year(const TagLib_Tag *tag);
unsigned int taglib_tag_track(const TagLib_Tag *tag);
void taglib_tag_set_title(TagLib_Tag *tag, const char *title);
void taglib_tag_set_artist(TagLib_Tag *tag, const char *artist);
void taglib_tag_set_album(TagLib_Tag *tag, const char *album);
void taglib_tag_set_comment(TagLib_Tag *tag, const char *comment);
void taglib_tag_set_genre(TagLib_Tag *tag, const char *genre);
void taglib_tag_set_year(TagLib_Tag *tag, unsigned int year);
void taglib_tag_set_track(TagLib_Tag *tag, unsigned int track);
void taglib_tag_free_strings(void);
int taglib_audioproperties_length(const TagLib_AudioProperties *audioProperties);
int taglib_audioproperties_bitrate(const TagLib_AudioProperties *audioProperties);
int taglib_audioproperties_samplerate(const TagLib_AudioProperties *audioProperties);
int taglib_audioproperties_channels(const TagLib_AudioProperties *audioProperties);
void taglib_id3v2_set_default_text_encoding(TagLib_ID3v2_Encoding encoding);
]]
local FILE, TAG, AUDIO = {}, {}, {}
local lib = ffi_load("libtag_c")
local taglib = {}
function taglib:__index(n)
    if n == "title" then
        return ffi_str(lib.taglib_tag_title(self[TAG]))
    elseif n == "artist" then
        return ffi_str(lib.taglib_tag_artist(self[TAG]))
    elseif n == "album" then
        return ffi_str(lib.taglib_tag_album(self[TAG]))
    elseif n == "comment" then
        return ffi_str(lib.taglib_tag_comment(self[TAG]))
    elseif n == "genre" then
        return ffi_str(lib.taglib_tag_genre(self[TAG]))
    elseif n == "year" then
        return lib.taglib_tag_year(self[TAG])
    elseif n == "track" then
        return lib.taglib_tag_track(self[TAG])
    elseif n == "length" then
        return lib.taglib_audioproperties_length(self[AUDIO])
    elseif n == "bitrate" then
        return lib.taglib_audioproperties_bitrate(self[AUDIO])
    elseif n == "samplerate" then
        return lib.taglib_audioproperties_samplerate(self[AUDIO])
    elseif n == "channels" then
        return lib.taglib_audioproperties_channels(self[AUDIO])
    else
        return rawget(taglib, n)
    end
end
function taglib:__newindex(n, v)
    if n == "title" then
        assert(type(v) == "string", "title field's value should be of type string.")
        lib.taglib_tag_set_title(self[TAG], v)
    elseif n == "artist" then
        assert(type(v) == "string", "artist field's value should be of type string.")
        lib.taglib_tag_set_artist(self[TAG], v)
    elseif n == "album" then
        assert(type(v) == "string", "album field's value should be of type string.")
        lib.taglib_tag_set_album(self[TAG], v)
    elseif n == "comment" then
        assert(type(v) == "string", "comment field's value should be of type string.")
        lib.taglib_tag_set_comment(self[TAG], v)
    elseif n == "genre" then
        assert(type(v) == "string", "genre field's value should be of type string.")
        lib.taglib_tag_set_genre(self[TAG], v)
    elseif n == "year" then
        assert(type(v) == "number", "year field's value should be of type number.")
        lib.taglib_tag_set_year(self[TAG], v)
    elseif n == "track" then
        assert(type(v) == "number", "track field's value should be of type number.")
        lib.taglib_tag_set_track(self[TAG], v)
    else
        rawset(self, n, v)
    end
end
function taglib:save()
    return lib.taglib_file_save(self[FILE]) ~= 0
end
function taglib.set_string_unicode(enabled)
    lib.taglib_set_strings_unicode(enabled and 1 or 0)
end
function taglib.set_string_management_enabled(enabled)
    lib.taglib_set_string_management_enabled(enabled and 1 or 0)
end
function taglib.free(pointer)
    lib.taglib_free(pointer)
end
function taglib.tag_free_strings()
    lib.taglib_tag_free_strings()
end
function taglib.id3v2_set_default_text_encoding(encoding)
    lib.taglib_id3v2_set_default_text_encoding(encoding)
end
function taglib.new(filename, filetype)
    assert(type(filename) == "string", "taglib.new first argument should be of type string.")
    local file = filetype and lib.taglib_file_new_type(filename, filetype) or lib.taglib_file_new(filename)
    assert(lib.taglib_file_is_valid(file) ~= 0, "invalid file.")
    file = ffi_gc(file, lib.taglib_file_free)
    local tag   = lib.taglib_file_tag(file)
    local audio = lib.taglib_file_audioproperties(file)
    local self  = { unicode = true, management = true }
    self[FILE]  = file
    self[TAG]   = tag
    self[AUDIO] = audio
    return setmetatable(self, taglib)
end
return taglib
