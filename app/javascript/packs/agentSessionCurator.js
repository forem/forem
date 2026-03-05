/**
 * Shared curation UI for agent sessions.
 * Used by both the upload/new page (post-parse) and the edit page.
 *
 * Usage:
 *   initCurator({
 *     container: document.getElementById('agent-session-curator'),
 *     messages: [...],
 *     curatedSelections: [...],
 *     slices: [...],
 *     sessionId: null | '123',       // null for unsaved sessions
 *     sessionSlug: null | 'my-slug',
 *     mode: 'upload' | 'edit',
 *     onSave: function(data) { ... },       // for upload mode: receives { curated, slices }
 *     onCurationChange: function(data) { ... }, // optional callback when curation changes
 *   });
 */

(function() {
  if (typeof window === 'undefined') return;
  window.AgentSessionCurator = { init: initCurator };

  function initCurator(config) {
    var curator = config.container;
    if (!curator) return;

    var messages = config.messages || [];
    var curated = new Set((config.curatedSelections || []).map(Number));
    var slices = config.slices || [];
    var container = curator.querySelector('.curator-messages') || curator.querySelector('#curator-messages');
    var countEl = curator.querySelector('.agent-session-curator-count') || curator.querySelector('#selection-count');
    var activeFilter = 'all';
    var sessionId = config.sessionId;
    var sessionSlug = config.sessionSlug;
    var mode = config.mode || 'edit';
    var useCuratedData = config.useCuratedData || false;

    if (curated.size === 0) {
      messages.forEach(function(m) { curated.add(m.index); });
    }

    // === Slice mode state ===
    var sliceMode = false;
    var sliceSelection = new Set();
    var editingSliceIndex = -1;

    // === Selection state ===
    var isDragging = false;
    var dragAction = null;
    var dragStartIndex = null;
    var dragCurrentIndex = null;
    var lastClickedIndex = -1;

    // === Helpers ===
    function escapeHtml(text) {
      var d = document.createElement('div');
      d.textContent = text;
      return d.innerHTML;
    }

    function msgHasToolCalls(msg) {
      return (msg.content || []).some(function(b) { return b.type === 'tool_call'; });
    }

    function msgHasOnlyToolCalls(msg) {
      var blocks = msg.content || [];
      return blocks.length > 0 && blocks.every(function(b) { return b.type === 'tool_call'; });
    }

    function msgHasRedactions(msg) {
      return (msg.content || []).some(function(b) {
        var text = (b.text || '') + (b.input || '') + (b.output || '');
        return text.indexOf('[REDACTED]') !== -1;
      });
    }

    function isVisible(msg) {
      if (activeFilter === 'all') return true;
      if (activeFilter === 'conversation') return !msgHasOnlyToolCalls(msg);
      if (activeFilter === 'user') return msg.role === 'user';
      if (activeFilter === 'tools') return msgHasToolCalls(msg);
      if (activeFilter === 'redacted') return msgHasRedactions(msg);
      return true;
    }

    function getActiveSet() {
      return sliceMode ? sliceSelection : curated;
    }

    function csrfToken() {
      var meta = document.querySelector("meta[name='csrf-token']");
      return meta ? meta.getAttribute('content') : '';
    }

    // === Rendering ===
    function renderMessages() {
      container.innerHTML = '';
      var activeSet = getActiveSet();

      messages.forEach(function(msg) {
        var div = document.createElement('div');
        var isSelected = activeSet.has(msg.index);
        var visible = isVisible(msg);

        div.className = 'curator-card' +
          (isSelected ? ' selected' : ' deselected') +
          (!visible ? ' filtered-out' : '') +
          (sliceMode ? ' slice-mode' : '');
        div.dataset.index = msg.index;

        var roleBar = document.createElement('div');
        roleBar.className = 'curator-card-bar curator-card-bar-' + msg.role;
        div.appendChild(roleBar);

        var body = document.createElement('div');
        body.className = 'curator-card-body';

        var header = document.createElement('div');
        header.className = 'curator-card-header';

        var roleLabel = document.createElement('span');
        roleLabel.className = 'curator-role curator-role-' + msg.role;
        roleLabel.textContent = msg.role === 'user' ? 'You' : 'Agent';
        header.appendChild(roleLabel);

        var indexLabel = document.createElement('span');
        indexLabel.className = 'curator-index-label';
        indexLabel.textContent = '#' + msg.index;
        header.appendChild(indexLabel);

        if (msg.timestamp) {
          var ts = document.createElement('span');
          ts.className = 'curator-timestamp';
          ts.textContent = new Date(msg.timestamp).toLocaleTimeString();
          header.appendChild(ts);
        }

        var indicator = document.createElement('span');
        indicator.className = 'curator-selected-indicator';
        indicator.textContent = isSelected ? (sliceMode ? 'in slice' : 'included') : (sliceMode ? '' : 'excluded');
        header.appendChild(indicator);

        body.appendChild(header);

        var content = document.createElement('div');
        content.className = 'curator-card-content';

        (msg.content || []).forEach(function(block) {
          if (block.type === 'text') {
            var text = block.text || '';
            if (text.length > 300) {
              var wrapper = document.createElement('div');
              wrapper.className = 'curator-text-expandable';

              var truncated = document.createElement('div');
              truncated.className = 'curator-text';
              truncated.textContent = text.substring(0, 300) + '...';
              wrapper.appendChild(truncated);

              var full = document.createElement('div');
              full.className = 'curator-text curator-text-full';
              full.style.display = 'none';
              full.textContent = text;
              wrapper.appendChild(full);

              var toggle = document.createElement('button');
              toggle.className = 'curator-expand-btn';
              toggle.textContent = '+ Show more';
              toggle.type = 'button';
              toggle.addEventListener('click', function(e) {
                e.stopPropagation();
                var showing = full.style.display !== 'none';
                full.style.display = showing ? 'none' : 'block';
                truncated.style.display = showing ? 'block' : 'none';
                toggle.textContent = showing ? '+ Show more' : '- Show less';
              });
              wrapper.appendChild(toggle);
              content.appendChild(wrapper);
            } else {
              var p = document.createElement('div');
              p.className = 'curator-text';
              p.textContent = text;
              content.appendChild(p);
            }
          } else if (block.type === 'tool_call') {
            var tool = document.createElement('div');
            tool.className = 'curator-tool-pill';
            tool.innerHTML = '<span class="curator-tool-name">' + escapeHtml(block.name) + '</span>' +
              (block.input ? '<span class="curator-tool-input">' + escapeHtml(String(block.input).substring(0, 50)) + '</span>' : '');
            content.appendChild(tool);
          }
        });

        body.appendChild(content);

        // Slice membership badges
        if (!sliceMode) {
          var sliceBadges = getSlicesForMessage(msg.index);
          if (sliceBadges.length > 0) {
            var badgeRow = document.createElement('div');
            badgeRow.className = 'curator-slice-badges';
            sliceBadges.forEach(function(s) {
              var badge = document.createElement('span');
              badge.className = 'curator-slice-badge';
              badge.textContent = s.name;
              badgeRow.appendChild(badge);
            });
            body.appendChild(badgeRow);
          }
        }

        div.appendChild(body);

        div.addEventListener('mousedown', function(e) {
          if (e.button !== 0) return;
          if (e.target.closest('.curator-expand-btn')) return;
          e.preventDefault();

          if (e.shiftKey && lastClickedIndex >= 0) {
            var lo = Math.min(lastClickedIndex, msg.index);
            var hi = Math.max(lastClickedIndex, msg.index);
            var action = activeSet.has(lastClickedIndex) ? 'select' : 'deselect';
            for (var i = lo; i <= hi; i++) {
              var m = messages.find(function(x) { return x.index === i; });
              if (m && isVisible(m)) {
                if (action === 'select') activeSet.add(i); else activeSet.delete(i);
              }
            }
            lastClickedIndex = msg.index;
            renderMessages();
            return;
          }

          isDragging = true;
          dragStartIndex = msg.index;
          dragCurrentIndex = msg.index;
          dragAction = activeSet.has(msg.index) ? 'deselect' : 'select';
          applyAction(msg.index, dragAction);
          lastClickedIndex = msg.index;
        });

        div.addEventListener('mouseenter', function() {
          if (!isDragging) return;
          if (!isVisible(msg)) return;
          dragCurrentIndex = msg.index;
          updateDragRange();
        });

        container.appendChild(div);
      });

      updateCount();
    }

    function getSlicesForMessage(index) {
      return slices.filter(function(s) {
        return (s.indices || []).indexOf(index) !== -1;
      });
    }

    function applyAction(index, action) {
      var activeSet = getActiveSet();
      if (action === 'select') activeSet.add(index); else activeSet.delete(index);
      updateCardVisual(index);
      updateCount();
    }

    function updateDragRange() {
      var activeSet = getActiveSet();
      var lo = Math.min(dragStartIndex, dragCurrentIndex);
      var hi = Math.max(dragStartIndex, dragCurrentIndex);

      messages.forEach(function(m) {
        if (!isVisible(m)) return;
        var inRange = m.index >= lo && m.index <= hi;
        var card = container.querySelector('[data-index="' + m.index + '"]');

        if (inRange) {
          if (dragAction === 'select') activeSet.add(m.index); else activeSet.delete(m.index);
          if (card) card.classList.add('drag-highlight');
        } else {
          if (card) card.classList.remove('drag-highlight');
        }
        updateCardVisual(m.index);
      });
      updateCount();
    }

    function updateCardVisual(index) {
      var activeSet = getActiveSet();
      var card = container.querySelector('[data-index="' + index + '"]');
      if (!card) return;
      var isSelected = activeSet.has(index);
      card.classList.toggle('selected', isSelected);
      card.classList.toggle('deselected', !isSelected);
      var indicator = card.querySelector('.curator-selected-indicator');
      if (indicator) indicator.textContent = isSelected ? (sliceMode ? 'in slice' : 'included') : (sliceMode ? '' : 'excluded');
    }

    document.addEventListener('mouseup', function() {
      if (isDragging) {
        isDragging = false;
        dragAction = null;
        dragStartIndex = null;
        dragCurrentIndex = null;
        container.querySelectorAll('.drag-highlight').forEach(function(el) {
          el.classList.remove('drag-highlight');
        });
      }
    });

    container.addEventListener('selectstart', function(e) {
      if (isDragging) e.preventDefault();
    });

    function updateCount() {
      var activeSet = getActiveSet();
      if (sliceMode) {
        var ct = activeSet.size;
        if (countEl) countEl.textContent = ct + ' message' + (ct !== 1 ? 's' : '') + ' in slice';
        var bannerCount = curator.querySelector('#slice-banner-count');
        if (bannerCount) bannerCount.textContent = ct + ' selected';
      } else {
        if (countEl) countEl.textContent = curated.size + ' of ' + messages.length + ' included';
      }
      if (config.onCurationChange) {
        config.onCurationChange({ curated: Array.from(curated).sort(function(a,b){ return a-b; }), slices: slices });
      }
    }

    // === Filters ===
    var filterBtns = curator.querySelectorAll('.curator-filter');
    filterBtns.forEach(function(btn) {
      btn.addEventListener('click', function() {
        filterBtns.forEach(function(b) { b.classList.remove('active'); });
        btn.classList.add('active');
        activeFilter = btn.dataset.filter;
        renderMessages();
      });
    });

    // === Bulk actions ===
    var selectAllBtn = curator.querySelector('#select-all-btn');
    if (selectAllBtn) {
      selectAllBtn.addEventListener('click', function() {
        var activeSet = getActiveSet();
        messages.forEach(function(m) {
          if (isVisible(m)) activeSet.add(m.index);
        });
        renderMessages();
      });
    }

    var selectNoneBtn = curator.querySelector('#select-none-btn');
    if (selectNoneBtn) {
      selectNoneBtn.addEventListener('click', function() {
        var activeSet = getActiveSet();
        messages.forEach(function(m) {
          if (isVisible(m)) activeSet.delete(m.index);
        });
        renderMessages();
      });
    }

    // === Save curation (edit mode: PATCH to server; upload mode: delegate to onSave) ===
    var saveCurationBtn = curator.querySelector('#save-curation-btn');
    if (saveCurationBtn) {
      saveCurationBtn.addEventListener('click', function() {
        if (sliceMode) return;
        var btn = this;

        if (mode === 'upload') {
          if (config.onSave) {
            config.onSave({
              curated: Array.from(curated).sort(function(a,b){ return a-b; }),
              slices: slices
            });
          }
          return;
        }

        // Edit mode: save to server
        btn.disabled = true;
        btn.textContent = 'Saving...';

        var payload;
        if (useCuratedData) {
          // New flow: send curated messages as curated_data
          var curatedIndices = new Set(Array.from(curated));
          var curatedMsgs = messages.filter(function(m) { return curatedIndices.has(m.index); });
          var reindexed = curatedMsgs.map(function(m, i) { return Object.assign({}, m, { index: i }); });
          var curatedDataObj = { messages: reindexed, metadata: {} };
          payload = { agent_session: { curated_data: JSON.stringify(curatedDataObj) } };
        } else {
          var selections = Array.from(curated).sort(function(a,b){ return a-b; });
          payload = { agent_session: { curated_selections: selections } };
        }

        fetch('/agent_sessions/' + sessionId, {
          method: 'PATCH',
          headers: { 'X-CSRF-Token': csrfToken(), 'Content-Type': 'application/json', 'Accept': 'application/json' },
          body: JSON.stringify(payload),
          credentials: 'same-origin',
        }).then(function(response) {
          return response.json();
        }).then(function(data) {
          btn.disabled = false;
          if (data.success) {
            btn.textContent = 'Saved!';
            setTimeout(function() { btn.textContent = 'Save'; }, 2000);
          } else {
            btn.textContent = 'Save';
            alert('Error: ' + (data.error || 'Unknown error'));
          }
        }).catch(function() {
          btn.disabled = false;
          btn.textContent = 'Save';
          alert('Error saving curation');
        });
      });
    }

    // ===========================================================================
    // SLICES
    // ===========================================================================

    function enterSliceMode(name, existingIndices) {
      sliceMode = true;
      sliceSelection = new Set(existingIndices || []);
      var banner = curator.querySelector('#slice-banner');
      if (banner) banner.style.display = 'flex';
      var bannerName = curator.querySelector('#slice-banner-name');
      if (bannerName) bannerName.textContent = name;
      var nameInput = curator.querySelector('#slice-name-input');
      if (nameInput) nameInput.style.display = 'none';
      container.classList.add('slice-mode-active');
      if (saveCurationBtn) saveCurationBtn.style.display = 'none';
      renderMessages();
    }

    function exitSliceMode() {
      sliceMode = false;
      editingSliceIndex = -1;
      sliceSelection = new Set();
      var banner = curator.querySelector('#slice-banner');
      if (banner) banner.style.display = 'none';
      var nameInput = curator.querySelector('#slice-name-input');
      if (nameInput) nameInput.style.display = 'none';
      container.classList.remove('slice-mode-active');
      if (saveCurationBtn) saveCurationBtn.style.display = '';
      renderMessages();
    }

    var newSliceBtn = curator.querySelector('#new-slice-btn');
    if (newSliceBtn) {
      newSliceBtn.addEventListener('click', function() {
        editingSliceIndex = -1;
        var nameInput = curator.querySelector('#slice-name-input');
        if (nameInput) nameInput.style.display = 'block';
        var nameField = curator.querySelector('#slice-name-field');
        if (nameField) { nameField.value = ''; nameField.focus(); }
      });
    }

    var cancelNameBtn = curator.querySelector('#cancel-name-btn');
    if (cancelNameBtn) {
      cancelNameBtn.addEventListener('click', function() {
        var nameInput = curator.querySelector('#slice-name-input');
        if (nameInput) nameInput.style.display = 'none';
      });
    }

    var startSliceBtn = curator.querySelector('#start-slice-btn');
    if (startSliceBtn) {
      startSliceBtn.addEventListener('click', function() {
        var nameField = curator.querySelector('#slice-name-field');
        var name = nameField ? nameField.value.trim() : '';
        if (!name) {
          if (nameField) nameField.focus();
          return;
        }
        if (editingSliceIndex === -1) {
          var exists = slices.some(function(s) { return s.name.toLowerCase() === name.toLowerCase(); });
          if (exists) {
            alert('A slice with this name already exists. Please choose a different name.');
            return;
          }
        }
        enterSliceMode(name, []);
      });
    }

    var nameField = curator.querySelector('#slice-name-field');
    if (nameField) {
      nameField.addEventListener('keydown', function(e) {
        if (e.key === 'Enter') {
          e.preventDefault();
          if (startSliceBtn) startSliceBtn.click();
        }
      });
    }

    var cancelSliceBtn = curator.querySelector('#cancel-slice-btn');
    if (cancelSliceBtn) {
      cancelSliceBtn.addEventListener('click', function() {
        exitSliceMode();
      });
    }

    var saveSliceBtn = curator.querySelector('#save-slice-btn');
    if (saveSliceBtn) {
      saveSliceBtn.addEventListener('click', function() {
        var bannerName = curator.querySelector('#slice-banner-name');
        var name = bannerName ? bannerName.textContent : '';
        var indices = Array.from(sliceSelection).sort(function(a,b){ return a-b; });

        if (indices.length === 0) {
          alert('Please select at least one message for this slice.');
          return;
        }

        if (editingSliceIndex >= 0) {
          slices[editingSliceIndex] = { name: name, indices: indices };
        } else {
          slices.push({ name: name, indices: indices });
        }

        if (mode === 'edit' && sessionId) {
          saveSlicesToServer(function() {
            exitSliceMode();
            renderSlicesList();
          });
        } else {
          // Upload mode: just update local state
          exitSliceMode();
          renderSlicesList();
        }
      });
    }

    function saveSlicesToServer(callback) {
      fetch('/agent_sessions/' + sessionId, {
        method: 'PATCH',
        headers: { 'X-CSRF-Token': csrfToken(), 'Content-Type': 'application/json', 'Accept': 'application/json' },
        body: JSON.stringify({ agent_session: { slices: slices } }),
        credentials: 'same-origin',
      }).then(function(response) {
        return response.json();
      }).then(function(data) {
        if (data.success) {
          if (data.agent_session && data.agent_session.slices) {
            slices = data.agent_session.slices;
          }
          if (callback) callback();
        } else {
          alert('Error saving slices: ' + (data.error || 'Unknown error'));
        }
      }).catch(function() {
        alert('Error saving slices');
      });
    }

    function renderSlicesList() {
      var list = curator.querySelector('#slices-list');
      if (!list) return;
      list.innerHTML = '';

      if (slices.length === 0) {
        list.innerHTML = '<p class="slices-empty">No slices yet.</p>';
        return;
      }

      slices.forEach(function(slice, index) {
        var card = document.createElement('div');
        card.className = 'slice-card';

        var header = document.createElement('div');
        header.className = 'slice-card-header';

        var nameEl = document.createElement('span');
        nameEl.className = 'slice-card-name';
        nameEl.textContent = slice.name;
        header.appendChild(nameEl);

        var countBadge = document.createElement('span');
        countBadge.className = 'slice-card-count';
        countBadge.textContent = (slice.indices || []).length;
        header.appendChild(countBadge);

        card.appendChild(header);

        if (sessionSlug) {
          var embedCode = document.createElement('code');
          embedCode.className = 'slice-card-embed';
          embedCode.textContent = '{% agent_session ' + sessionSlug + ' ' + slice.name + ' %}';
          card.appendChild(embedCode);
        }

        var actions = document.createElement('div');
        actions.className = 'slice-card-actions';

        if (sessionSlug) {
          var copyBtn = document.createElement('button');
          copyBtn.type = 'button';
          copyBtn.className = 'slice-action-btn';
          copyBtn.textContent = 'Copy';
          copyBtn.title = 'Copy embed code';
          copyBtn.addEventListener('click', function() {
            var embedEl = card.querySelector('.slice-card-embed');
            if (embedEl) {
              navigator.clipboard.writeText(embedEl.textContent).then(function() {
                copyBtn.textContent = 'Copied!';
                setTimeout(function() { copyBtn.textContent = 'Copy'; }, 2000);
              });
            }
          });
          actions.appendChild(copyBtn);
        }

        var editBtn = document.createElement('button');
        editBtn.type = 'button';
        editBtn.className = 'slice-action-btn';
        editBtn.textContent = 'Edit';
        editBtn.addEventListener('click', function() {
          editingSliceIndex = index;
          enterSliceMode(slice.name, slice.indices || []);
        });
        actions.appendChild(editBtn);

        var deleteBtn = document.createElement('button');
        deleteBtn.type = 'button';
        deleteBtn.className = 'slice-action-btn slice-action-btn--danger';
        deleteBtn.textContent = 'Delete';
        deleteBtn.addEventListener('click', function() {
          if (!confirm('Delete slice "' + slice.name + '"?')) return;
          slices.splice(index, 1);
          if (mode === 'edit' && sessionId) {
            saveSlicesToServer(function() {
              renderSlicesList();
              renderMessages();
            });
          } else {
            renderSlicesList();
            renderMessages();
          }
        });
        actions.appendChild(deleteBtn);

        card.appendChild(actions);
        list.appendChild(card);
      });
    }

    // Initial render
    renderMessages();
    renderSlicesList();

    // Return API for external access
    return {
      getCurated: function() { return Array.from(curated).sort(function(a,b){ return a-b; }); },
      getSlices: function() { return slices; },
      getMessages: function() { return messages; },
      updateMessages: function(newMessages) {
        messages = newMessages;
        curated = new Set();
        messages.forEach(function(m) { curated.add(m.index); });
        renderMessages();
        renderSlicesList();
      },
    };
  }
})();
