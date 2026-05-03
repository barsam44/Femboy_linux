@echo off
echo Merging model.gguf...
copy /b model.gguf.part_* ..\model.gguf
echo Done! model.gguf is in the parent folder.
