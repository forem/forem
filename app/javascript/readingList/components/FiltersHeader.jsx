<div className="filters-header">
  {Boolean(selectedTags.length) && (
    <a
      className="filters-header-action"
      href={isStatusViewValid ? READING_LIST_PATH : READING_LIST_ARCHIVE_PATH}
      onClick={this.clearSelectedTags}
      data-no-instant
    >
      clear all
    </a>
  )}
</div>;
<div className="filters-header">
  {Boolean(selectedTags.length) && (
    <a
      className="filters-header-action"
      href={isStatusViewValid ? READING_LIST_PATH : READING_LIST_ARCHIVE_PATH}
      onClick={this.clearSelectedTags}
      data-no-instant
    >
      clear all
    </a>
  )}
</div>;
