DECLARE
  l_html CLOB := '';

  CURSOR c_pages IS
    SELECT
      RANK() OVER (ORDER BY total_views DESC) AS page_rank,
      CASE RANK() OVER (ORDER BY total_views DESC)
        WHEN 1 THEN 'rank-1' ELSE '' END AS rank1_class,
      '#' || RANK() OVER (ORDER BY total_views DESC)
        || CASE RANK() OVER (ORDER BY total_views DESC)
             WHEN 1 THEN ' - TOP' ELSE '' END AS rank_label,
      page_id,
      page_name,
      TO_CHAR(total_views,'FM999,999') AS view_count_fmt,
      ROUND(total_views*100.0/SUM(total_views) OVER()) AS pct_of_total,
      CASE RANK() OVER (ORDER BY total_views DESC)
        WHEN 1 THEN 'rgba(99,55,255,0.30)'
        WHEN 2 THEN 'rgba(0,183,255,0.25)'
        WHEN 3 THEN 'rgba(0,230,160,0.22)'
        WHEN 4 THEN 'rgba(251,146,60,0.25)'
        WHEN 5 THEN 'rgba(244,63,94,0.22)'
        ELSE        'rgba(163,230,53,0.20)'
      END AS icon_bg,
      CASE RANK() OVER (ORDER BY total_views DESC)
        WHEN 1 THEN '#a78bfa' WHEN 2 THEN '#38bdf8'
        WHEN 3 THEN '#34d399' WHEN 4 THEN '#fb923c'
        WHEN 5 THEN '#f472b6' ELSE '#a3e635'
      END AS accent_color,
      CASE RANK() OVER (ORDER BY total_views DESC)
        WHEN 1 THEN '#6337ff' WHEN 2 THEN '#0ea5e9'
        WHEN 3 THEN '#059669' WHEN 4 THEN '#ea580c'
        WHEN 5 THEN '#db2777' ELSE '#65a30d'
      END AS glow_color,
      CASE RANK() OVER (ORDER BY total_views DESC)
        WHEN 1 THEN 'linear-gradient(90deg,#6337ff,#a78bfa)'
        WHEN 2 THEN 'linear-gradient(90deg,#0ea5e9,#38bdf8)'
        WHEN 3 THEN 'linear-gradient(90deg,#059669,#34d399)'
        WHEN 4 THEN 'linear-gradient(90deg,#ea580c,#fb923c)'
        WHEN 5 THEN 'linear-gradient(90deg,#db2777,#f472b6)'
        ELSE        'linear-gradient(90deg,#65a30d,#a3e635)'
      END AS bar_gradient,
      CASE page_id
        WHEN 1    THEN 'fa-home'
        WHEN 2    THEN 'fa-users'
        WHEN 3    THEN 'fa-bar-chart'
        WHEN 4    THEN 'fa-file-text-o'
        WHEN 5    THEN 'fa-cog'
        WHEN 9999 THEN 'fa-sign-in'
        ELSE           'fa-file-o'
      END AS page_icon,
      CASE WHEN week_current >= week_prior THEN 'up' ELSE 'down' END AS trend_class,
      CASE WHEN week_current >= week_prior THEN '&uarr;' ELSE '&darr;' END AS trend_arrow,
      CASE
        WHEN week_prior IS NULL OR week_prior = 0
        THEN 'New this week'
        ELSE ABS(ROUND((week_current - week_prior)*100.0 / week_prior)) || '% vs last week'
      END AS trend_display
    FROM (
      SELECT
        v.page_id, v.page_name,
        COUNT(*) AS total_views,
        SUM(CASE WHEN v.viewed_on >= TRUNC(SYSDATE,'IW')
                 THEN 1 ELSE 0 END) AS week_current,
        SUM(CASE WHEN v.viewed_on >= TRUNC(SYSDATE,'IW')-7
                 AND  v.viewed_on <  TRUNC(SYSDATE,'IW')
                 THEN 1 ELSE 0 END) AS week_prior
      FROM apex_page_views v
      WHERE v.app_id    = :APP_ID
        AND v.viewed_on >= SYSDATE - 30
      GROUP BY v.page_id, v.page_name
    )
    ORDER BY total_views DESC
    FETCH FIRST 6 ROWS ONLY;

BEGIN
  l_html := l_html || '<div class="gm-wrapper">';
  l_html := l_html || '<div class="gm-orb gm-orb-1"></div>';
  l_html := l_html || '<div class="gm-orb gm-orb-2"></div>';
  l_html := l_html || '<div class="gm-orb gm-orb-3"></div>';
  l_html := l_html || '<div class="gm-orb gm-orb-4"></div>';
  l_html := l_html || '<div class="gm-grid-bg"></div>';
  l_html := l_html || '<div class="gm-header"><div>';
  l_html := l_html || '<div class="gm-eyebrow">Page Analytics</div>';
  l_html := l_html || '<h2 class="gm-title">Most Visited Pages</h2>';
  l_html := l_html || '<p class="gm-subtitle">Last 30 days · Your application activity</p>';
  l_html := l_html || '</div><div class="gm-live-badge">';
  l_html := l_html || '<span class="gm-live-dot"></span>Live Tracking';
  l_html := l_html || '</div></div>';
  l_html := l_html || '<div class="gm-grid-cards">';

  FOR r IN c_pages LOOP
    l_html := l_html || '<a class="gm-card" href="f?p=' || :APP_ID || ':' || r.page_id || ':' || :APP_SESSION || '::NO::">';
    l_html := l_html || '<div class="gm-card-glow" style="background:' || r.glow_color || ';"></div>';
    l_html := l_html || '<div class="gm-rank-badge ' || r.rank1_class || '">' || r.rank_label || '</div>';
    l_html := l_html || '<div class="gm-icon-wrap" style="background:' || r.icon_bg || ';color:' || r.accent_color || ';">';
    l_html := l_html || '<span class="fa ' || r.page_icon || '"></span></div>';
    l_html := l_html || '<div class="gm-page-name">' || APEX_ESCAPE.HTML(r.page_name) || '</div>';
    l_html := l_html || '<div class="gm-count">' || r.view_count_fmt || '</div>';
    l_html := l_html || '<div class="gm-count-label">page views</div>';
    l_html := l_html || '<div class="gm-bar-track"><div class="gm-bar-fill" style="width:' || r.pct_of_total || '%;background:' || r.bar_gradient || ';"></div></div>';
    l_html := l_html || '<div class="gm-trend ' || r.trend_class || '">';
    l_html := l_html || '<span class="gm-trend-arrow">' || r.trend_arrow || '</span>';
    l_html := l_html || '<span>' || r.trend_display || '</span></div>';
    l_html := l_html || '<div class="gm-card-footer">';
    l_html := l_html || '<span class="gm-pct-label">Share of total</span>';
    l_html := l_html || '<span class="gm-pct-value" style="color:' || r.accent_color || ';">' || r.pct_of_total || '%</span>';
    l_html := l_html || '</div></a>';
  END LOOP;

  l_html := l_html || '</div></div>';

  RETURN l_html;

END;
