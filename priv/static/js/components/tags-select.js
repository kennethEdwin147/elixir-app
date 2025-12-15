import {LitElement, html} from 'https://cdn.jsdelivr.net/gh/lit/dist@2/core/lit-core.min.js';

/**
 * TAGS SELECT COMPONENT
 * 
 * Multi-select component pour sélectionner des tags
 * 
 * USAGE:
 * 
 * 1. Importer le composant dans votre HTML:
 *    <script type="module" src="/js/components/tags-select.js"></script>
 * 
 * 2. Utiliser dans le formulaire:
 *    <tags-select id="tags"></tags-select>
 *    <input type="hidden" name="tags" id="tagsInput">
 * 
 * 3. Écouter les changements:
 *    <script type="module">
 *      document.getElementById('tags').addEventListener('change', (e) => {
 *        console.log(e.detail.values); // ['mic', 'chill', 'eu']
 *        document.getElementById('tagsInput').value = JSON.stringify(e.detail.values);
 *      });
 *    </script>
 * 
 * EVENTS:
 * - 'change': Déclenché quand les tags changent
 *   - e.detail.values: Array des valeurs sélectionnées
 * 
 * FEATURES:
 * - Multi-sélection
 * - Recherche en temps réel
 * - Pills cliquables avec X pour retirer
 * - Click outside pour fermer
 * - Style Tailwind
 */
class TagsSelect extends LitElement {
  static properties = {
    open: {type: Boolean},
    selected: {type: Array},
    search: {type: String}
  };

  createRenderRoot() {
    return this;
  }

  constructor() {
    super();
    this.open = false;
    this.selected = [];
    this.search = '';
    this.options = [
      {value: 'mic', label: 'Mic'},
      {value: 'no-mic', label: 'No Mic'},
      {value: 'chill', label: 'Chill'},
      {value: 'competitive', label: 'Competitive'},
      {value: 'eu', label: 'EU'},
      {value: 'na', label: 'NA'}
    ];
  }

  render() {
    const filteredOptions = this.options.filter(o => 
      !this.selected.includes(o.value) && 
      o.label.toLowerCase().includes(this.search.toLowerCase())
    );

    return html`
      <div class="relative w-full">
        <div 
          @click=${() => this.open = true}
          class="w-full min-h-[42px] px-3 py-4 text-black rounded-lg  bg-gray-100 cursor-text
                 focus-within:ring-indigo-500 focus-within:border-indigo-500 transition-shadow 
                 flex flex-wrap gap-2 items-center"
        >
          ${this.selected.map(value => {
            const option = this.options.find(o => o.value === value);
            return html`
              <span class="inline-flex items-center gap-1 px-3 py-1 bg-indigo-100 text-indigo-700 rounded-full">
                ${option?.label}
                <button 
                  type="button"
                  @click=${(e) => this._remove(e, value)}
                  class="hover:text-indigo-900"
                >✕</button>
              </span>
            `;
          })}
          
          <input 
            type="text" 
            placeholder=${this.selected.length === 0 ? 'Select tags...' : ''}
            .value=${this.search}
            @input=${this._handleSearch}
            @focus=${() => this.open = true}
            @click=${e => e.stopPropagation()}
            class="flex-1 min-w-[120px] placeholder-black text-black outline-none bg-transparent"
          >
        </div>

        ${this.open && filteredOptions.length > 0 ? html`
          <div class="absolute top-full left-0 right-0 mt-1 max-w-sm bg-white rounded-lg shadow-lg z-50 max-h-60 overflow-y-auto">
            ${filteredOptions.map((option, index) => html`
              <div 
                @click=${() => this._add(option.value)}
                class="px-5 py-3 cursor-pointer hover:bg-gray-50  text-gray-900 ${index === 0 ? 'bg-gray-50' : ''}"
              >
                ${option.label}
              </div>
            `)}
          </div>
        ` : ''}
      </div>
    `;
  }

  _handleSearch(e) {
    this.search = e.target.value;
    this.open = true;
  }

  _add(value) {
    this.selected = [...this.selected, value];
    this.search = '';
    this.dispatchEvent(new CustomEvent('change', {detail: {values: this.selected}}));
  }

  _remove(e, value) {
    e.stopPropagation();
    this.selected = this.selected.filter(v => v !== value);
    this.dispatchEvent(new CustomEvent('change', {detail: {values: this.selected}}));
  }

 connectedCallback() {
  super.connectedCallback();
  
  this._clickOutside = (e) => {
    // Vérifier si le click est en dehors du composant
    if (!this.contains(e.target)) {
      this.open = false;
    }
  };
  
  // Écouter sur le parent modal OU sur document
  const modal = this.closest('modal-dialog');
  const listener = modal || document;
  listener.addEventListener('click', this._clickOutside, true);  // ← true = capture phase
}

disconnectedCallback() {
  super.disconnectedCallback();
  const modal = this.closest('modal-dialog');
  const listener = modal || document;
  listener.removeEventListener('click', this._clickOutside, true);
}

  
}

customElements.define('tags-select', TagsSelect);