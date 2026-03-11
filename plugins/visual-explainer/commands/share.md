# Share Visual Explainer Page

Share a visual explainer HTML file instantly via Cloudflare R2. Returns a live URL with no authentication required.

## Usage

```
/share <file-path>
```

**Arguments:**
- `file-path` - Path to the HTML file to share (required)

**Examples:**
```
/share ~/.agent/diagrams/my-diagram.html
/share /tmp/visual-explainer-output.html
```

## How It Works

1. Copies your HTML file to Cloudflare R2 (`cquenced-staging` bucket) under `shared-visuals/`
2. File is served publicly via `staging.cquenced.com`
3. Returns a live URL immediately

## Requirements

- **R2 credentials** in `~/.claude.json` under `mcpServers.s3.env` (S3_ACCESS_KEY_ID, S3_SECRET_ACCESS_KEY)
- **boto3** Python package

## Script Location

```bash
bash {{skill_dir}}/scripts/share.sh <file>
```

## Output

```
Sharing my-diagram.html...

Shared successfully!

Live URL: https://staging.cquenced.com/shared-visuals/my-diagram-20260311-143022.html
```

The script also outputs JSON for programmatic use:
```json
{"url":"https://staging.cquenced.com/shared-visuals/my-diagram-20260311-143022.html","key":"shared-visuals/my-diagram-20260311-143022.html","size":17466}
```

## Notes

- Deployments are **public** -- anyone with the URL can view
- Files persist in R2 until manually removed
- Each share creates a unique URL with a timestamp suffix
