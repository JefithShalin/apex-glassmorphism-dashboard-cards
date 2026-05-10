BEGIN
  INSERT INTO apex_page_views (
    app_id,
    page_id,
    page_name,
    viewed_by
  )
  SELECT
    :APP_ID,
    :APP_PAGE_ID,
    p.page_name,
    :APP_USER
  FROM apex_application_pages p
  WHERE p.application_id = :APP_ID
    AND p.page_id        = :APP_PAGE_ID;

  COMMIT;
END;
