# Deploy routines

Instructions for Claude when invoked by `.github/workflows/deploy-routines.yml`.

For every file matching `routines/*.prompt.md` in this checkout:

1. Read the file. Parse the YAML frontmatter for `trigger_id`, `model`,
   and `allowed_tools`.
2. Extract the body below the closing `---` of the frontmatter — call
   it BODY.
3. Call the `RemoteTrigger` tool with `action: update`, the file's
   `trigger_id`, and this body shape:

   ```json
   {
     "job_config": {
       "ccr": {
         "events": [{
           "data": {
             "message": {
               "content": "<BODY>",
               "role": "user"
             },
             "type": "user"
           }
         }],
         "session_context": {
           "allowed_tools": "<from frontmatter>",
           "model": "<from frontmatter>"
         }
       }
     }
   }
   ```

4. Verify by calling `RemoteTrigger` `action: get` for the same
   `trigger_id` and confirming the returned
   `job_config.ccr.events[0].data.message.content` equals BODY exactly.

Print one `PASS <basename>` or `FAIL <basename> — <reason>` line per
file. Exit non-zero if any FAIL.

Do not modify this repository.
