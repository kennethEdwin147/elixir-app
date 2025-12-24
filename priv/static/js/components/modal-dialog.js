/**
 * MODAL DIALOG COMPONENT
 * 
 * USAGE:
 * 
 * <modal-dialog id="myModal" title="Add topics">
 *   <form>
 *     <!-- Votre contenu ici -->
 *   </form>
 * </modal-dialog>
 * 
 * <button onclick="document.getElementById('myModal').open = true">
 *   Ouvrir Modal
 * </button>
 * 
 * EVENTS:
 * - 'close': Déclenché quand le modal se ferme
 */
import {LitElement, html} from 'https://cdn.jsdelivr.net/gh/lit/dist@2/core/lit-core.min.js';

class ModalDialog extends LitElement {
  static properties = {
    open: {type: Boolean},
    title: {type: String}
  };

  createRenderRoot() {
    return this;
  }

  constructor() {
    super();
    this.open = false;
    this.title = '';
    this._originalContent = null;
    this._contentParent = null;
  }

  render() {
    if (!this.open) {
      this.style.display = 'none';
      return html``;
    }

    this.style.display = 'block';

    return html`
      <div 
        @click=${this._close}
        class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4 animate-fadeIn"
      >
        <div 
          @click=${e => e.stopPropagation()}
          class="bg-white bottom-4 absolute rounded-t-xl py-2 shadow-2xl max-w-sm w-full h-full max-h-[85vh] overflow-hidden animate-slideUp"
        >
          <div class="flex items-center justify-between px-6 py-2 ">
            <h2 class="text-3xl font-extrabold text-gray-900">${this.title}</h2>
            <button 
              @click=${this._close}
              class="text-gray-400 hover:text-gray-600 transition-colors rounded-full p-1 hover:bg-gray-100"
            >
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>

          <div id="modal-content" class="px-6 py-2 overflow-y-auto h-full">
          </div>
        </div>
      </div>
    `;
  }

  updated(changedProperties) {
    if (changedProperties.has('open')) {
      if (this.open) {
        const modalContent = this.querySelector('#modal-content');
        
        if (this._originalContent) {
          // Réutiliser le contenu déjà sauvegardé
          modalContent.appendChild(this._originalContent);
        } else {
          // Première fois : chercher et sauvegarder
          const content = this.querySelector('[slot="content"]');
          
          if (content && modalContent) {
            this._originalContent = content;
            this._contentParent = content.parentNode;
            modalContent.appendChild(content);
          }
        }
        
        document.body.style.overflow = 'hidden';
        
      } else {
        // Fermeture : remettre le contenu à sa place
        if (this._originalContent && this._contentParent) {
          this._contentParent.appendChild(this._originalContent);
        }
        
        document.body.style.overflow = '';
      }
    }
  }

  _close() {
    this.open = false;
    this.dispatchEvent(new CustomEvent('close'));
  }

  connectedCallback() {
    super.connectedCallback();
    
    this._handleEscape = (e) => {
      if (e.key === 'Escape' && this.open) {
        this._close();
      }
    };
    document.addEventListener('keydown', this._handleEscape);
  }

  disconnectedCallback() {
    super.disconnectedCallback();
    document.removeEventListener('keydown', this._handleEscape);
    document.body.style.overflow = '';
  }
}

customElements.define('modal-dialog', ModalDialog);