# run

```bash

podman run -it --rm \
--userns=keep-id \
-v "$(pwd):/workspace" \
-w "/workspace" \
-e "OPENCODE_AUTH=$(< ~/.local/share/opencode/auth.json)" \
opencode-dev bash

```
