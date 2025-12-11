<script type="module">
  import {LitElement, html} from 'https://cdn.jsdelivr.net/gh/lit/dist@2/core/lit-core.min.js';

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
      // Options hardcodées pour tags
      this.options = [
        {value: 'mic', label: 'Mic'},
        {value: 'no-mic', label: 'No Mic'},
        {value: 'chill', label: 'Chill'},
        {value: 'competitive', label: 'Competitive'},
        {value: 'eu', label: 'EU'},
        {value: 'na', label: 'NA'},
        {value: 'asia', label: 'Asia'},
        {value: 'fr', label: 'FR'},
        {value: 'en', label: 'EN'},
        {value: 'beginner', label: 'Beginner'},
        {value: 'experienced', label: 'Experienced'}
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
            class="w-full min-h-[42px] px-3 py-2 border-2 border-gray-200 rounded-2xl bg-white cursor-text
                   focus-within:ring-indigo-500 focus-within:border-indigo-500 transition-shadow duration-150 shadow-sm
                   flex flex-wrap gap-2 items-center"
          >
            ${this.selected.map(value => {
              const option = this.options.find(o => o.value === value);
              return html`
                <span class="inline-flex items-center gap-1 px-3 py-1 bg-indigo-100 text-indigo-700 rounded-full text-sm">
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
              class="flex-1 min-w-[120px] outline-none bg-transparent text-sm"
            >
          </div>

          ${this.open && filteredOptions.length > 0 ? html`
            <div class="absolute top-full left-0 right-0 mt-1 bg-white border-2 border-gray-200 rounded-2xl shadow-lg z-50 max-h-60 overflow-y-auto">
              ${filteredOptions.map((option, index) => html`
                <div 
                  @click=${() => this._add(option.value)}
                  class="px-5 py-3 cursor-pointer hover:bg-gray-50 text-sm text-gray-900 transition-colors ${index === 0 ? 'bg-gray-50' : ''}"
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
        if (!this.contains(e.target)) this.open = false;
      };
      document.addEventListener('click', this._clickOutside);
    }

    disconnectedCallback() {
      super.disconnectedCallback();
      document.removeEventListener('click', this._clickOutside);
    }
  }

  customElements.define('tags-select', TagsSelect);
</script>

<!-- USAGE SIMPLE -->
<form>
  <tags-select id="tags"></tags-select>
  <input type="hidden" name="tags" id="tagsInput">
  
  <button type="submit">Publier</button>
</form>

<script>
  document.getElementById('tags').addEventListener('change', (e) => {
    document.getElementById('tagsInput').value = JSON.stringify(e.detail.values);
  });
</script>