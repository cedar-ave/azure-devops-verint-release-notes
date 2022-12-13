# Create release notes from Azure DevOps work items using Bravo Notes and publish in a Verint community

This project supports a process for:

1. Generating release notes from a filtered list of Azure DevOps work items using the [Bravo Notes](https://marketplace.visualstudio.com/items?itemName=agile-extensions.bravo-notes) Azure DevOps extension
2. Exporting the release notes as a Markdown file into Azure DevOps to create a pull request for review by stakeholders
3. Transforming the Markdown file into an HTML file posted on a Verint customer community page by a local script

- [Output](#output)
- [Prerequisites](#prerequisites)
- [Steps](#steps)
  - [First time only](#first-time-only)
  - [Every time](#every-time)
- [Process overview](#process-overview)
  - [Azure DevOps work items](#azure-devops-work-items)
    - [Logic](#logic)
    - [Fields](#fields)
      - [How to add or change custom tabs and fields](#how-to-add-or-change-custom-tabs-and-fields)
  - [Bravo Notes](#bravo-notes)
    - [Template](#template)
      - [Example with multiple products](#example-with-multiple-products)
        - [Labels](#labels)
    - [How to find Azure DevOps field names to use in a Bravo Notes template](#how-to-find-azure-devops-field-names-to-use-in-a-bravo-notes-template)
- [Reference](#reference)
  - [Get Verint API token](#get-verint-api-token)
  - [Get Verint wiki page ID(s)](#get-verint-wiki-page-ids)
  - [Custom CSS](#custom-css)
  - [Upload images](#upload-images)
    - [Steps to upload images](#steps-to-upload-images)
      - [Example](#example)
        - [Directory structure](#directory-structure)
        - [key.json](#keyjson)

## Output

Notes on the Verint page are published in the following format:

```
Page name
Subtitle

Contents
- Date (link to notes for this date below)
- Date (link to notes for this date below)
- Date (link to notes for this date below)
- Etc.

Date
  Contents
  - This is something new (link to detailed note below)
  - This is something else new (link to detailed note below)
  - This is another new thing (link to detailed note below)
  - This is yet another new thing (link to detailed note below)
  - Fixed bugs (link to list of fixed bugs)

  New features
    Product 1
      This is something new
        This is a description

      This is something else new
        This is a description

      Etc.

    Product 2
      This is another new thing
        This is a description

      This is yet another new thing
        This is a description

      Etc.

  Fixed bugs
    Product 1
    - Bug
    - Bug
    - Etc.

    Product 2
    - Bug
    - Bug
    - Etc.

Date
...

Date
...
```

The process also accommodates the following use case:

- Release notes information in the Azure DevOps work item is contained in a rich-text HTML field
- Rich-text HTML is not adequately transformed when exported to Markdown

This documentation supports a use case of publishing release notes for multiple products in a single publication in the forms of traditional release notes and known issues. The process can be modified to support notes for a single product or other forms of publications.

This process also can be executed with an Azure DevOps pipeline using the Bravo Notes release pipeline extension.

## Prerequisites

- Subscription to the [Bravo Notes](https://marketplace.visualstudio.com/items?itemName=agile-extensions.bravo-notes) Azure DevOps extension
- Verint API token (see [Get Verint API token](#get-verint-api-token))
- Verint ID(s):
  - Wiki page IDs of page(s) to post the notes to (see [Get Verint wiki page ID(s)](#get-verint-wiki-page-ids) below)
  - Gallery ID(s) to store images (if uploading images; see [Upload images](#upload-images) below)
- [jq](https://stedolan.github.io/jq) (if uploading images)
- [Pandoc](https://pandoc.org/installing.html)
- [juice](https://www.npmjs.com/package/juice) (see [Custom CSS](#custom-css))
- `YYYY` director(ies) at root of the repo, e.g.:

```plaintext
1_html-to-md.sh
2_assemble-markdown.sh
3_md-to-html.sh
img.sh
only-toc-on-existing-md.sh
2022
2023
etc.
```

## Steps

### First time only

| Step | What to do | Details below |
|-|-|-|
| 1 | Determine how you will correspond Azure DevOps work item fields to components of release notes (default and/or custom). | [Azure DevOps work items](#azure-devops-work-items) |
| 2 | Create a template in Bravo Notes using those fields. Create labels using those fields. The template must include `**Contents**` and `**Scroll up slightly after the jump**` or the scripts must be adjusted. | [Bravo Notes](#bravo-notes) |
| 3 | Create one or more `YYYY` directories in root. The `YYYY` directory must contain a subdirectory and files or the script throws errors. I.e., don't make a new YYYY directory until there are files to put in it. | [Prerequisites](#prerequisites) |
| 4 | Customize [style.css](style.css). | [Custom styles](#custom-css) |

### Every time

| Step | What to do | Details |
|-|-|-|
| 1 | Export a file from Bravo Notes (1) as HTML, (2) in the following format: `YYYY-MM-DD.html`, and (3) to the root of the repo. | |
| 2 | Move the file to the root of a `YYYY` directory. | |
| 3 | Run [1_html-to-md.sh](1_html-to-md.sh). This transforms the Markdown to HTML. The exported Markdown file is in `YYYY`. |  |
| 4 | If desired, run [image.sh](image.sh) to upload image(s) to Verint and output(s) the URL so they can be inserted in the published page on Verint. | [Upload images](#upload-images) |
| 5 | Create, review, and complete a pull request, if desired. | |
| 6 | If titles of notes changed, run [only-toc-on-existing-md.sh](only-toc-on-existing-md.sh) after updating the date variables. This updates the table of contents for a release date file if the file was changed after the original table of contents is generated. | |
| 7 | Run [2_assemble-markdown.sh](2_assemble-markdown.sh). This assembles all release notes files in reverse chronological order and adds a master table of contents. | |
| 8 | Run [3_md-to-html.sh](3_md-to-html.sh) after adding `$yearName` and `pageId` variables beginning in line 25. This transforms the exported Markdown to HTML, applies [CSS styles](style.css) supported by Verint, and posts it on Verint. | |

## Process overview

### Azure DevOps work items

Release notes and known issues are generated from Azure DevOps queries that return work items that meet the following criteria:

#### Logic

Logic behind how certain fields are marked on certain work items determines if contents in a work item form a release note, known issue, or none.

| Work item type                  | State     | Severity | Publish | Under the section |
|---------------------------------|-----------|----------|---------|-------------------|
| Feature or product backlog item | Closed    | N/A      | Yes     | `What's new` item |
| Bug                             | Closed    | N/A      | Yes     | Fixed bug         |
| Bug                             | <> Closed | N/A      | Yes     | Known issue       |

#### Fields

Custom fields are not required; default fields like `Title` and `Description` are adequate to transform to a note title and description. However, custom fields may provide finer-grained control through functionality like dropdowns and Boolean selections. For example, the following fields are on a custom `RN` tab of all Feature, Product Backlog Item, and Bug work item types.

| Field               | What it is                                                        | Type           |
|---------------------|-------------------------------------------------------------------|----------------|
| Publish             | Toggle to indicate if the work item should be published as a note | Boolean toggle |
| Release Note        | Field to write the release note                                   | Rich HTML text |
| Product(s) Affected | Dropdown to select which DOS product(s) the note is about         | Multi-select   |
| Version(s) Affected | Dropdown to select which DOS version(s) the note applies to       | Multi-select   |

##### How to add or change custom tabs and fields

- Go to the process​ page in Azure DevOps.
- Go to the bug and features template.
- Add a new tab, if desired.
- Add custom fields.

Note: The same field can be on both the default `Details` tab and a custom tab. When adding data in a work item, you only need to update the field on one of the tabs. The update manifests in both fields.

### Bravo Notes

Bravo Notes:

- Automatically generates a list of release notes from Azure DevOps work items
- Uses custom Handlebars logic in a template to:
  - Filter out work items that don't meet the work item logic
  - Use designated fields in a work item to curate a note with a title, description, and work item ID
  - Sort notes by product/category/etc. (if needed)
- Exports a file of the notes to a repo

#### Template

See the [Bravo Notes documentation](https://help.agileextensions.com/collection/1-bravo-notes) to customize a template.

##### Example with multiple products

```handlebars
# <a id="DD_Month_YYYY"></a>{{releaseDate}}

**Contents**

Scroll up slightly after the jump.

## New features

### Product 1
{{#filter 'product-1-new'}}
{{#if workItems}}
{{#workItems orderByDescending='ID'}}

### {{field 'Title'}}
{{{ field-html 'Platform.ReleaseNote' }}} ([{{ field 'System.Id' }}](https://<organization>.visualstudio.com/CAP/_workitems/edit/{{ field 'System.Id' }}))
{{/workItems}}
{{else}}
None
{{/if}}
{{/filter}}

### Product 2
{{#filter 'product-2-new'}}
{{#if workItems}}
{{#workItems orderByDescending='ID'}}

### {{field 'Title'}}
{{{ field-html 'Platform.ReleaseNote' }}} ([{{ field 'System.Id' }}](https://<organization>.visualstudio.com/CAP/_workitems/edit/{{ field 'System.Id' }}))
{{/workItems}}
{{else}}
None
{{/if}}
{{/filter}}

## Fixed bugs

### Product 1
{{#filter 'product-1-fixed'}}
{{#if workItems}}
{{#workItems orderByDescending='ID'}}
- {{ field 'Platform.ReleaseNote' }} ([{{ field 'System.Id' }}](https://<organization>.visualstudio.com/CAP/_workitems/edit/{{ field 'System.Id' }}))
{{/workItems}}
{{else}}
None
{{/if}}
{{/filter}}

### Product 2
{{#filter 'product-2-fixed'}}
{{#if workItems}}
{{#workItems orderByDescending='ID'}}
- {{ field 'Platform.ReleaseNote' }} ([{{ field 'System.Id' }}](https://<organization>.visualstudio.com/CAP/_workitems/edit/{{ field 'System.Id' }}))
{{/workItems}}
{{else}}
None
{{/if}}
{{/filter}}
```

Note: Correspond a case change to `Fixed bugs` or other fixed elements with code in the scripts.

###### Labels

**New features**

![](https://github.com/cedar-ave/azure-devops-verint-release-notes/blob/main/bravo-notes-examples/label-new.png)

**Fixed bugs**

![](https://github.com/cedar-ave/azure-devops-verint-release-notes/blob/main/bravo-notes-examples/label-fixed.png)

#### How to find Azure DevOps field names to use in a Bravo Notes template

Directly: `https://dev.azure.com/<organization>/<project>/_apis/wit/fields?api-version=5.1`

In cURL: `curl -u EMAIL:ADO_PAT --request GET "https://dev.azure.com/<organization>/<project>/_apis/wit/wiql/<id>?api-version=5.1"`

In an application like Postman, send a basic authorization `GET` request to `https://dev.azure.com/<organization>/<project>/_apis/wit/fields?api-version=5.1`.

- Username: Email (depending on organization)
- Password: Azure DevOps personal access token

## Reference

### Get Verint API token

- Your Verint community > Avatar at top right > **Settings** > Scroll down to **API Keys** > Click **Manage application API keys**. Copy your key.
- Go to something like [https://www.base64decode.org](https://www.base64decode.org) > Click **Encode** at top of page > Enter `API_KEY:username` > Click **Encode**. This is your REST user token.​​​​​​​

### Get Verint wiki page ID(s)

The wiki page ID is in the page's URL, e.g.:

```plaintext
https://community.<organization>.com/group-name/w/wiki-name/1234/page
```

### Custom CSS

Verint accepts custom styles, but in some cases, they may need to be inline. Customize CSS in [style.css](#custom-css).

The following line in `3_md-to-html.sh` applies styles from a CSS file to a file as inline styles:

```plaintext
juice --css style.css input.html output.html
```

### Upload images

To appear in Verint, images must be:

1. Uploaded to Verint using Verint's CFS endpoint
2. Referenced in the Markdown file with the image's CFS URL

`upload-image.sh` uploads an image and returns the URL.

#### Steps to upload images

1. Add a `media` directory in `YYYY-MM-DD`.
2. In the `media` directory, add:
   - The image files
   - A `key.json` file (see example below)
3. Update the following in `upload-image.sh`:
   - Date variables at the top
   - Verint token near the top and middle of the script
   - Gallery ID*
4. See the output in `url.txt`.

##### Example

###### Directory structure

```plaintext
repo/
  YYYY/
    MM-DD-YY/
      media/
        key.json
        my-image-1.png
        my-image-2.png
        my-image-3.png
```        

###### key.json

```json
[
  {
    "filename": "my-image-1.png",
    "title": "My image 1"
  },
  {
    "filename": "my-image-2.png",
    "title": "My image 2"
  },
  {
    "filename": "my-image-3.png",
    "title": "My image 3"
  }
]
```

*To get a Gallery ID, apply the following request in one of [these scripts](https://github.com/cedar-ave/verint-get-content-data): `https://community.healthcatalyst.com/api.ashx/v2/galleries.json`