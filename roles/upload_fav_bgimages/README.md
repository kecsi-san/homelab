# upload_fav_bgimages

Uploads a collection of wallpaper images to the system and registers them in the GNOME background picker.

## What it does

1. Ensures `/usr/share/backgrounds/` exists
2. Copies all images from `files/` to `/usr/share/backgrounds/`
3. Ensures `/usr/share/gnome-background-properties/` exists
4. Generates `fav-backgrounds.xml` so images appear in GNOME Settings → Background

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `fav_bgimages` | see `defaults/main.yml` | List of image filenames to upload and register |

## Usage

```yaml
- name: Upload favourite background images
  ansible.builtin.import_role:
    name: upload_fav_bgimages
  become: true
  tags:
    - bgimages
    - desktop
```

Run standalone with:

```bash
ansible-playbook -t bgimages playbooks/k8s-nodes.yml
```

## Notes

- Requires `become: true`: writes to system directories
- Images must be placed in `roles/upload_fav_bgimages/files/`
- Override `fav_bgimages` in group_vars to use a different image set per host group
