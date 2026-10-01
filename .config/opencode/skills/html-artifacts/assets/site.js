(function () {
  const PAGES = window.SITE_PAGES || [];
  const SITE_TITLE = window.SITE_TITLE || '';

  function renderSitebar() {
    const bar = document.querySelector('header.sitebar');
    if (!bar) return;
    if (!PAGES.length) { bar.remove(); return; }
    const current = location.pathname.split('/').pop() || 'index.html';
    const links = PAGES.map(([href, label]) => {
      const cur = href === current ? ' aria-current="page"' : '';
      return `<a href="${href}"${cur}>${label}</a>`;
    }).join('');
    bar.innerHTML = `<div class="sitebar__inner"><a class="sitebar__brand" href="${PAGES[0][0]}">${SITE_TITLE}</a><nav>${links}</nav></div>`;
  }

  function scrollSpy() {
    const toc = document.getElementById('toc');
    if (!toc) return;
    const links = [...toc.querySelectorAll('a')];
    const sections = links
      .map((link) => ({ link, el: document.getElementById(link.getAttribute('href').slice(1)) }))
      .filter((s) => s.el);
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        links.forEach((l) => l.classList.remove('active'));
        const match = sections.find((s) => s.el === entry.target);
        if (match) {
          match.link.classList.add('active');
          if (innerWidth <= 1060) match.link.scrollIntoView({ block: 'nearest', inline: 'center' });
        }
      });
    }, { rootMargin: '-12% 0px -78% 0px' });
    sections.forEach((s) => observer.observe(s.el));
  }

  function quiz() {
    document.querySelectorAll('.qcard').forEach((card) => {
      const btn = card.querySelector('button');
      if (btn) btn.addEventListener('click', () => card.classList.add('revealed'));
    });
    const all = document.getElementById('reveal-all');
    if (all) all.addEventListener('click', () => document.querySelectorAll('.qcard').forEach((c) => c.classList.add('revealed')));
  }

  function filters() {
    document.querySelectorAll('.filterbar').forEach((bar) => {
      const table = document.getElementById(bar.dataset.target);
      if (!table) return;
      const buttons = [...bar.querySelectorAll('button')];
      buttons.forEach((btn) => btn.addEventListener('click', () => {
        buttons.forEach((b) => b.setAttribute('aria-pressed', String(b === btn)));
        const f = btn.dataset.filter;
        table.querySelectorAll('tbody tr').forEach((row) => {
          const tags = (row.dataset.tags || '').split(' ');
          row.style.display = f === 'all' || tags.includes(f) ? '' : 'none';
        });
      }));
    });
  }

  function cssVar(name) {
    return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  }

  async function diagrams() {
    const shells = [...document.querySelectorAll('.diagram-shell')];
    if (!shells.length) return;
    const { default: mermaid } = await import('https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs');
    const isDark = matchMedia('(prefers-color-scheme: dark)').matches;
    mermaid.initialize({
      startOnLoad: false,
      theme: 'base',
      look: 'classic',
      securityLevel: 'loose',
      sequence: { mirrorActors: false, messageAlign: 'left', boxMargin: 8, noteMargin: 10, actorMargin: 60, wrap: true, width: 170 },
      flowchart: { curve: 'basis', padding: 14 },
      themeVariables: {
        fontFamily: "'Inter', -apple-system, system-ui, sans-serif",
        fontSize: '15px',
        background: cssVar('--surface'),
        primaryColor: isDark ? '#1c1c1c' : '#f3f3f3',
        primaryBorderColor: cssVar('--text-dim'),
        primaryTextColor: cssVar('--text'),
        secondaryColor: isDark ? '#11302c' : '#e4f2ef',
        secondaryBorderColor: cssVar('--after'),
        secondaryTextColor: cssVar('--text'),
        tertiaryColor: isDark ? '#2c2614' : '#f6efde',
        tertiaryBorderColor: cssVar('--ours'),
        tertiaryTextColor: cssVar('--text'),
        lineColor: cssVar('--text-dim'),
        textColor: cssVar('--text'),
        actorBkg: isDark ? '#1c1c1c' : '#f3f3f3',
        actorBorder: cssVar('--text-dim'),
        actorTextColor: cssVar('--text'),
        actorLineColor: cssVar('--border-strong'),
        signalColor: cssVar('--text'),
        signalTextColor: cssVar('--text'),
        labelBoxBkgColor: cssVar('--surface-2'),
        labelBoxBorderColor: cssVar('--border-strong'),
        labelTextColor: cssVar('--text'),
        loopTextColor: cssVar('--text'),
        noteBkgColor: isDark ? '#1c1c1c' : '#f6f6f6',
        noteTextColor: cssVar('--text'),
        noteBorderColor: cssVar('--border-strong'),
        activationBkgColor: cssVar('--surface-3'),
        activationBorderColor: cssVar('--text-dim'),
        sequenceNumberColor: cssVar('--bg'),
        clusterBkg: isDark ? '#111111' : '#fafafa',
        clusterBorder: cssVar('--border-strong'),
        edgeLabelBackground: cssVar('--surface'),
      },
    });
    for (const shell of shells) initDiagram(shell, mermaid, isDark);
  }

  let activeDrag = null;
  addEventListener('mousemove', (e) => activeDrag && activeDrag.onMove(e));
  addEventListener('mouseup', () => { if (activeDrag) activeDrag.onEnd(); activeDrag = null; });

  function initDiagram(shell, mermaid, isDark) {
    const source = shell.querySelector('.diagram-source');
    if (!source) return;
    const caption = shell.querySelector('.diagram-shell__caption');
    const wrap = document.createElement('div');
    wrap.className = 'mermaid-wrap';
    wrap.innerHTML = `<div class="zoom-controls">
        <button type="button" data-action="zoom-in" title="Zoom in">+</button>
        <button type="button" data-action="zoom-out" title="Zoom out">&minus;</button>
        <button type="button" data-action="zoom-fit" title="Fit">&#8634;</button>
        <button type="button" data-action="zoom-one" title="1:1">1:1</button>
        <button type="button" data-action="zoom-expand" title="Open full size">&#x26F6;</button>
        <span class="zoom-label">…</span></div>
      <div class="mermaid-viewport"><div class="mermaid mermaid-canvas"></div></div>`;
    wrap.title = 'Ctrl/Cmd + scroll to zoom, drag to pan, double-click to fit';
    shell.insertBefore(wrap, caption || null);

    const viewport = wrap.querySelector('.mermaid-viewport');
    const canvas = wrap.querySelector('.mermaid-canvas');
    const label = wrap.querySelector('.zoom-label');
    const cfg = { pad: 16, minH: 200, maxHpx: 2400, maxHvh: 3, maxInit: 1.05, minZ: 0.08, maxZ: 6, step: 0.14, floor: 0.4 };
    const clamp = (n, lo, hi) => Math.max(lo, Math.min(hi, n));
    let zoom = 1, panX = 0, panY = 0, svgW = 0, svgH = 0, mode = 'fit';

    function constrain() {
      const vw = viewport.clientWidth, vh = viewport.clientHeight, rw = svgW * zoom, rh = svgH * zoom;
      panX = rw + cfg.pad * 2 <= vw ? (vw - rw) / 2 : clamp(panX, vw - rw - cfg.pad, cfg.pad);
      panY = rh + cfg.pad * 2 <= vh ? (vh - rh) / 2 : clamp(panY, vh - rh - cfg.pad, cfg.pad);
    }
    function apply() {
      const svg = canvas.querySelector('svg');
      if (!svg || !svgW) return;
      constrain();
      svg.style.width = svgW * zoom + 'px';
      svg.style.height = svgH * zoom + 'px';
      canvas.style.transform = `translate(${panX}px, ${panY}px)`;
      label.textContent = Math.round(zoom * 100) + '%';
    }
    function canPan() {
      return svgW * zoom + cfg.pad * 2 > viewport.clientWidth || svgH * zoom + cfg.pad * 2 > viewport.clientHeight;
    }
    function fit() {
      if (!svgW) return;
      const aw = Math.max(80, viewport.clientWidth - cfg.pad * 2), ah = Math.max(80, viewport.clientHeight - cfg.pad * 2);
      let z = Math.min(aw / svgW, ah / svgH);
      mode = 'fit';
      if (z < cfg.floor) { z = aw / svgW; mode = 'width'; }
      zoom = clamp(z, cfg.minZ, cfg.maxInit);
      panX = (viewport.clientWidth - svgW * zoom) / 2;
      panY = cfg.pad;
      apply();
    }
    function one() { zoom = 1; mode = '1:1'; apply(); }
    function zoomAround(f, cx, cy) {
      const next = clamp(zoom * f, cfg.minZ, cfg.maxZ), r = next / zoom;
      panX = cx - r * (cx - panX); panY = cy - r * (cy - panY); zoom = next; mode = 'custom'; apply();
    }
    function height() {
      if (!svgW) return;
      const usable = Math.max(280, wrap.getBoundingClientRect().width - 2);
      const z = Math.min(usable / svgW, cfg.maxInit);
      const ideal = svgH * z + cfg.pad * 2;
      const hardMax = Math.min(cfg.maxHpx, Math.max(cfg.minH + 40, Math.floor(innerHeight * cfg.maxHvh)));
      wrap.style.height = Math.round(clamp(ideal, cfg.minH, hardMax)) + 'px';
    }
    function expand() {
      const svg = canvas.querySelector('svg');
      if (!svg) return;
      const clone = svg.cloneNode(true);
      clone.style.width = ''; clone.style.height = '';
      const bg = isDark ? '#0a0a0a' : '#ffffff';
      const html = `<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Diagram</title><style>body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;background:${bg};padding:40px;box-sizing:border-box}svg{max-width:100%;height:auto}</style></head><body>${clone.outerHTML}</body></html>`;
      open(URL.createObjectURL(new Blob([html], { type: 'text/html' })), '_blank');
    }
    const actions = { 'zoom-in': () => zoomAround(1 + cfg.step, viewport.clientWidth / 2, viewport.clientHeight / 2), 'zoom-out': () => zoomAround(1 / (1 + cfg.step), viewport.clientWidth / 2, viewport.clientHeight / 2), 'zoom-fit': fit, 'zoom-one': one, 'zoom-expand': expand };
    Object.entries(actions).forEach(([a, h]) => wrap.querySelector(`[data-action="${a}"]`).addEventListener('click', h));
    viewport.addEventListener('dblclick', fit);
    viewport.addEventListener('wheel', (e) => {
      if (e.ctrlKey || e.metaKey) {
        e.preventDefault();
        const r = viewport.getBoundingClientRect();
        zoomAround(e.deltaY < 0 ? 1 + cfg.step : 1 / (1 + cfg.step), e.clientX - r.left, e.clientY - r.top);
      }
    }, { passive: false });
    viewport.addEventListener('mousedown', (e) => {
      if (!canPan()) return;
      wrap.classList.add('is-panning');
      const sx = e.clientX, sy = e.clientY, spx = panX, spy = panY;
      e.preventDefault();
      activeDrag = { onMove: (ev) => { panX = spx + ev.clientX - sx; panY = spy + ev.clientY - sy; apply(); }, onEnd: () => wrap.classList.remove('is-panning') };
    });
    new ResizeObserver(() => { if (svgW) { height(); fit(); } }).observe(wrap);

    (async () => {
      try {
        const id = 'd' + Math.random().toString(36).slice(2, 9);
        const { svg } = await mermaid.render(id, source.textContent.trim());
        canvas.innerHTML = svg;
        const node = canvas.querySelector('svg');
        const vb = node.viewBox && node.viewBox.baseVal;
        svgW = (vb && vb.width) || parseFloat(node.getAttribute('width')) || node.getBBox().width;
        svgH = (vb && vb.height) || parseFloat(node.getAttribute('height')) || node.getBBox().height;
        if (!node.getAttribute('viewBox')) node.setAttribute('viewBox', `0 0 ${svgW} ${svgH}`);
        node.removeAttribute('width'); node.removeAttribute('height');
        node.style.maxWidth = 'none'; node.style.display = 'block';
        height(); fit();
      } catch (err) {
        console.error('Mermaid render failed', err);
        label.textContent = 'render error';
        canvas.innerHTML = `<pre style="padding:16px;color:var(--risk);white-space:pre-wrap">${String(err.message || err)}</pre>`;
      }
    })();
  }

  document.addEventListener('DOMContentLoaded', () => {
    renderSitebar();
    scrollSpy();
    quiz();
    filters();
    diagrams();
  });
})();
