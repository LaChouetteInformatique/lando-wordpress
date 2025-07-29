# Lando WordPress Boilerplate

## Goal

This project provides a template and workflow to initialize clean, production-ready local WordPress development environments in minutes.

The automated process delivers:
-   A fresh installation of the latest WordPress version inside a dedicated `app/` subdirectory.
-   A pre-configured site with your settings (title, admin credentials, etc.) via a simple `config.env` file.
-   Your favorite free and premium plugins installed and activated.
-   A **clean** installation: default plugins (Akismet, Hello Dolly) and unused themes are automatically removed.

The architecture separates development environment files (Lando, scripts) from application files (WordPress), which is ideal for migrations using plugins.

## Prerequisites

- Docker Desktop (Windows/macOS) or Docker Engine (Linux)
- Lando (latest stable version)
- WSL2 (for Windows users)
- Git
- `rsync` (typically installed by default on Linux and WSL)

---

## 1. Initial Setup (One-Time Only)

Before you can create projects, you must clone this template to your local machine. It will serve as the blueprint for all your future sites.

```bash
# Clone the template repository to your home directory
git clone https://your-repo.git ~/wordpress_template
```

> [!IMPORTANT]
> This `~/wordpress_template` directory is your source of truth. You will never work in it directly.

---

## 2. Project Creation Workflows

### Workflow A: Create a New Blank Site

This is the starting point for any new project, whether it's blank or a clone.

1.  **Initialize the Project Folder:**
    ```bash
    mkdir ~/my-new-site.dev && cd $_
    ```

2.  **Copy the Template (without Git history):**
    Use `rsync` to copy the template files while excluding the `.git` directory.
    ```bash
    rsync -av --exclude='.git' ~/wordpress_template/ .
    ```
    > [!NOTE]
    > This command ensures your new project is a clean slate, without inheriting the template's Git history.

3.  **Customize the Configuration:**
    -   **`.lando.yml`:** Edit the `name:` line to give your Lando project a unique name (e.g., `my-new-site-dev`).
    -   **`config.env`:** Adjust the site title, admin credentials, and the list of free plugins.

4.  **Initialize the Git Repository:**
    ```bash
    git init && git add . && git commit -m "Initial commit"
    ```

5.  **Start the Containers (`lando start`):**
    This command starts the services (web server, database) and prepares the WordPress files.
    ```bash
    lando start
    ```
    > [!NOTE]
    > At the end of this command, the site will show the WordPress installation screen. **This is normal and expected.** Wait for the command to finish (or press `CTRL+C` if it hangs on the `vitals` check) to proceed to the next step.

6.  **Get the Active URL (`lando info`):**
    Lando has chosen a port for your site. Get the exact URL with this command.
    ```bash
    lando info
    ```
    Find the main URL in the output (e.g., `http://my-new-site-dev.lndo.site:8000/`) and copy it.

7.  **Finalize the Installation (`lando install`):**
    Run our custom command, passing it the URL you just copied.
    ```bash
    # Syntax: lando install -- --url=<COPIED_URL>
    lando install -- --url=http://my-new-site-dev.lndo.site:8000
    ```
    > [!IMPORTANT]
    > The double dash `--` is crucial. It tells Lando to pass the `--url` argument directly to our script.

The script will install the site and create a `.lando-url.txt` file containing this URL for future reference. Your new site is now fully installed and accessible.

---

### Workflow B: Clone an Existing Site

There are two main methods to clone a site. Choose the one that fits your toolset.

#### Method 1: Manual Export/Import (with WP-CLI)

This method gives you full control over the process.

1.  **Export from Production:**
    -   SSH into your production server.
    -   Navigate to the site's root directory.
    -   Export the database: `wp db export backup_prod.sql`
    -   Archive the files: `tar -czvf wp-content.tar.gz wp-content`
    -   Download `backup_prod.sql` and `wp-content.tar.gz` to your local machine.

2.  **Create the Blank Local Environment:**
    -   Follow **all steps of Workflow A** to create a clean, functional local site.

3.  **Import Production Data Locally:**
    -   Place `backup_prod.sql` and `wp-content.tar.gz` in the root of your Lando project.
    -   Run the following commands:
        ```bash
        # 1. Import the production database, overwriting the blank one
        lando db-import backup_prod.sql

        # 2. Replace the wp-content directory
        rm -rf app/wp-content
        tar -xzvf wp-content.tar.gz -C app/
        ```

4.  **Finalize the Migration:**
    -   Update the URLs in the database:
        ```bash
        URL_LOCALE=$(cat .lando-url.txt)
        lando wp search-replace 'https://www.your-prod-site.com' "$URL_LOCALE" --all-tables
        ```
    -   Flush the cache and refresh permalinks:
        ```bash
        lando wp cache flush
        lando wp rewrite flush --hard
        ```
    -   Log in to `/wp-admin` using your **production** credentials.

---

#### Method 2: Restore via a Migration Plugin (e.g., WPvivid)

This method is often simpler if you don't have SSH access.

1.  **Export from Production:**
    -   On your production site, use your migration plugin (e.g., WPvivid) to create a full backup.
    -   Download the backup file(s) generated by the plugin.

2.  **Create the Blank Local Environment (with the migration plugin):**
    -   Follow **all steps of Workflow A**.
    -   **Crucial Point:** Before running `lando install`, ensure the migration plugin will be present on your local site.
        -   **Free Version:** Add the plugin's slug (e.g., `wpvivid-backuprestore`) to the `PLUGINS_LIST` in your `config.env` file.
        -   **Pro Version:** Place the plugin's `.zip` file in the `plugins-premium/` directory.
    -   Run `lando install` as usual.

3.  **Restore the Backup Locally:**
    -   Log in to the admin dashboard of your new, blank local site.
    -   Go to the interface of the migration plugin you just installed.
    -   Use its "Upload" or "Restore" feature to upload the backup file from your production site.
    -   Follow the plugin's instructions to run the restoration.

4.  **Finalize:**
    -   Most modern migration plugins automatically handle the URL `search-replace` during restoration.
    -   After the restore is complete, you will likely be logged out. Log back in using your **production** credentials.
    -   As a safety measure, go to `Settings > Permalinks` and click "Save Changes" to refresh the rewrite rules.

---

## Useful Lando Commands

```bash
# Starts the containers
lando start

# Finalizes the WordPress installation
lando install -- --url=<URL>

# Displays information (URLs, DB credentials, etc.)
lando info

# Runs a WP-CLI command
lando wp <command>

# Stops the environment
lando stop

# Completely destroys the environment (irreversible!)
lando destroy -y
```

## License

This project is dedicated to the public domain. For more details, see the [LICENSE](LICENSE) file.

---
*README generated by Gemini 2.5 Pro*