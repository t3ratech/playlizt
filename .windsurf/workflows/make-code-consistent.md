---
description: Make code consistent with the SYSTEM-DESIGN.md
auto_execution_mode: 1
---

### Check code documentation for truthfullness

- Go through the whole codebase and ensure that the documentation is being truthful at in every section based on the code.

- Once you are done with that, go back to the code and analyze that it trully follows what is in that document, and either update the document to match the code (if the code is doing it better or in another way which is acceptable), or update the code (if the document is proposing something better than what we are doing, or if the code is being inconsistent in some places.)

- This operation should happen repeatedly until we are at a consistent state, however, we are not trying to implement NEW functionality. If The functionality doesnt exist yet in code, you can leave the information in the document and we will build it later, as long as our current state can eventually be upgraded to that state