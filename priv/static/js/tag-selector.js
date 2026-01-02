class TagSelector extends HTMLElement {
  constructor() {
    super();
    this.tags = [];
  }

  connectedCallback() {
    const name = this.getAttribute('name') || 'tags';
    const placeholder = this.getAttribute('placeholder') || 'Ex: ranked, mic, chill';
    
    const suggestions = [
      'ranked', 'unrated', 'custom',
      'mic', 'no-mic',
      'chill', 'competitive',
      'duelist', 'controller', 'sentinel', 'initiator',
      'fr', 'en',
      'now', 'tonight', '18+'
    ];

    this.innerHTML = `
      <div class="tag-selector">
        <input 
          type="text" 
          name="${name}"
          placeholder="${placeholder}"
          autocomplete="off"
          class="tag-input">
        <div class="tag-suggestions" style="margin-top: 0px; padding: 8px; background: white; border: 1px solid #ccc;">
          ${suggestions.map(tag => `<span class="tag-chip" data-tag="${tag}">${tag}</span>`).join(' ')}
        </div>
      </div>
    `;

    this.input = this.querySelector('.tag-input');
    this.chips = this.querySelectorAll('.tag-chip');

    // Event listeners
    this.chips.forEach(chip => {
      chip.addEventListener('click', () => this.toggleTag(chip.dataset.tag));
    });
  }

  toggleTag(tag) {
    const currentValue = this.input.value.trim();
    const currentTags = currentValue
      ? currentValue.split(',').map(t => t.trim()).filter(Boolean)
      : [];
    
    if (currentTags.includes(tag)) {
      // Tag existe → SUPPRIME
      const filtered = currentTags.filter(t => t !== tag);
      this.input.value = filtered.join(', ');
    } else {
      // Tag n'existe pas → AJOUTE
      currentTags.push(tag);
      this.input.value = currentTags.join(', ');
    }
  }
}

customElements.define('tag-selector', TagSelector);