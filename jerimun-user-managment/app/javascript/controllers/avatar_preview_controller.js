import { Controller } from "@hotwired/stimulus";
export default class extends Controller {
  static targets = ["input", "image"];
  preview() {
    const file = this.inputTarget.files[0];
    if (!file) return;
    if (this.objectUrl) URL.revokeObjectURL(this.objectUrl);
    this.objectUrl = URL.createObjectURL(file);
    this.imageTarget.src = this.objectUrl;
    this.imageTarget.classList.remove("hidden");
  }
  disconnect() {
    if (this.objectUrl) URL.revokeObjectURL(this.objectUrl);
  }
}
