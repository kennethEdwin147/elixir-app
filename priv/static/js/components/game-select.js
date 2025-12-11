import {LitElement, html} from 'https://cdn.jsdelivr.net/gh/lit/dist@2/core/lit-core.min.js';

class GameSelect extends LitElement {
    static properties = {
        open: {type: Boolean},
        selected: {type: String},
        search: {type: String},
        options: {type: Array}
    };

    createRenderRoot() {
        return this;
    }

    constructor() {
        super();
        this.open = false;
        this.selected = '';
        this.search = '';
        this.options = [
        {value: 'valorant', label: 'Valorant'},
        {value: 'apex', label: 'Apex Legends'},
        {value: 'league', label: 'League of Legends'},
        {value: 'cs2', label: 'CS2'},
        {value: 'fortnite', label: 'Fortnite'}
        ];
    }

    render() {
        const filteredOptions = this.options.filter(o =>
        o.label.toLowerCase().includes(this.search.toLowerCase())
        );

        return html`
        <div class="relative w-full">
            <!-- Input avec search -->
            <input
            type="text"
            placeholder="Search for a game"
            .value=${this.search}
            @input=${this._handleSearch}
            @focus=${() => this.open = true}
            @click=${e => e.stopPropagation()}
            class="px-5 w-full font-bold focus:outline-none py-2 text-xs rounded-2xl text-black placeholder-black
                    focus:ring-indigo-500 focus:bg-gray-50 transition-shadow duration-150 shadow-sm bg-gray-100"
            >

            <!-- Dropdown options -->
            ${this.open && filteredOptions.length > 0 ? html`
            <div class="absolute max-w-xs top-full left-0 right-0 mt-1 bg-white rounded-2xl shadow-lg z-50 max-h-60 overflow-y-auto">
                ${filteredOptions.map((option, index) => html`
                <div
                    @click=${() => this._select(option)}
                    class="px-5 font-normal py-2 cursor-pointer pl-6 hover:bg-gray-50 text-sm text-gray-900 transition-colors
                        ${index === 0 ? 'bg-gray-50' : ''}
                        "
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

    _select(option) {
        this.selected = option.value;
        this.search = option.label;
        this.open = false;
        this.dispatchEvent(new CustomEvent('change', {detail: {value: option.value}}));
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

customElements.define('game-select', GameSelect);
