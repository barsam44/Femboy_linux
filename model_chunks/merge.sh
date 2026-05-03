#!/bin/bash
echo "Merging model.gguf..."
cat model.gguf.part_* > ../model.gguf
echo "Done! model.gguf is in the parent folder."
