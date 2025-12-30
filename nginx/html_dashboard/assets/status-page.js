/**
 * Status Page Logic
 * Fetches JSON data from the server and renders the status table.
 */
(() => {
  const $ = selector => document.querySelector(selector);
  const updatedElement = $('#updated');
  const tableBody = $('#status-body');
  const cardsContainer = $('#cards');
  
  // Date formatter for Spanish locale
  const dateFormatter = new Intl.DateTimeFormat('es-ES', { dateStyle: 'short', timeStyle: 'short' });

  // Helper: Create HTML badge
  const badge = isOnline => `<span class="badge ${isOnline ? 'ok' : 'err'}">${isOnline ? 'ONLINE' : 'OFFLINE'}</span>`;

  async function loadStatus() {
    try {
      if (tableBody) tableBody.innerHTML = '<tr><td colspan="3" class="muted">Cargando...</td></tr>';
      
      // Fetch status JSON with timestamp to prevent caching
      const response = await fetch('/assets/status.json?ts=' + Date.now(), { cache: 'no-store' });
      
      if (!response.ok) throw new Error(`HTTP Error: ${response.status}`);
      
      const data = await response.json();

      // Update "Last Updated" text
      if (updatedElement) {
        updatedElement.textContent = 'Actualizado: ' + dateFormatter.format(new Date());
      }
// Render Service Table Rows
      const rows = (data.services || []).map(service => `
        <tr>
          <td>${service.name || '—'}</td>
          <td>${badge(!!service.ok)}</td>
          <td>${service.ms !== undefined ? service.ms + ' ms' : '—'}</td>
        </tr>`).join('');
        
      tableBody.innerHTML = rows || '<tr><td colspan="3" class="muted">No hay servicios monitorizados.</td></tr>';

      // Note: Hardware metrics cards rendering logic omitted for brevity in this example.
      
    } catch (error) {
      console.error('Status fetch error:', error);
      if (tableBody) tableBody.innerHTML = '<tr><td colspan="3" class="muted">Error al obtener el estado del sistema.</td></tr>';
      if (updatedElement) updatedElement.textContent = 'Error de conexión';
    }
  }

  // Initialize and set auto-refresh interval (2 minutes)
  document.addEventListener('DOMContentLoaded', loadStatus);
  setInterval(loadStatus, 120000);
})();
