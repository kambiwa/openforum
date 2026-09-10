import { Editor } from "@tiptap/core"
import StarterKit from "@tiptap/starter-kit"
import Underline from "@tiptap/extension-underline"
import Subscript from "@tiptap/extension-subscript"
import Superscript from "@tiptap/extension-superscript"
import Color from "@tiptap/extension-color"
import { TextStyle } from "@tiptap/extension-text-style"
import Highlight from "@tiptap/extension-highlight"
import TextAlign from "@tiptap/extension-text-align"
import { Table } from "@tiptap/extension-table"
import TableRow from "@tiptap/extension-table-row"
import TableCell from "@tiptap/extension-table-cell"
import TableHeader from "@tiptap/extension-table-header"
import Image from "@tiptap/extension-image"
import Link from "@tiptap/extension-link"

const RichTextEditor = {
  mounted() {
    const toolbarEl = this.el.querySelector("[data-editor-toolbar]")
    const containerEl = this.el.querySelector("[data-editor-container]")
    const hiddenInput = document.getElementById(this.el.dataset.inputId)
    const initialValue = this.el.dataset.initialValue || ""

    this.editor = new Editor({
      element: containerEl,
      extensions: [
        StarterKit,
        Underline,
        Subscript,
        Superscript,
        TextStyle,
        Color,
        Highlight.configure({ multicolor: true }),
        TextAlign.configure({ types: ["heading", "paragraph"] }),
        Table.configure({ resizable: true }),
        TableRow,
        TableHeader,
        TableCell,
        Image,
        Link.configure({ openOnClick: false, autolink: true })
      ],
      content: initialValue,
      editorProps: {
        attributes: {
          class: "prose prose-sm max-w-none focus:outline-none min-h-[180px]"
        }
      },
      onUpdate: ({ editor }) => {
        this.syncHiddenInput(editor, hiddenInput)
      }
    })

    this.bindToolbar(toolbarEl)
    this.updateToolbarState(toolbarEl)

    this.editor.on("selectionUpdate", () => this.updateToolbarState(toolbarEl))
    this.editor.on("transaction", () => this.updateToolbarState(toolbarEl))
  },

  destroyed() {
    if (this.editor) {
      this.editor.destroy()
      this.editor = null
    }
  },

  syncHiddenInput(editor, hiddenInput) {
    const isEmpty = editor.isEmpty
    hiddenInput.value = isEmpty ? "" : editor.getHTML()
    hiddenInput.dispatchEvent(new Event("input", { bubbles: true }))
  },

  bindToolbar(toolbarEl) {
    const editor = this.editor

    const commands = {
      bold: () => editor.chain().focus().toggleBold().run(),
      italic: () => editor.chain().focus().toggleItalic().run(),
      underline: () => editor.chain().focus().toggleUnderline().run(),
      strike: () => editor.chain().focus().toggleStrike().run(),
      subscript: () => editor.chain().focus().toggleSubscript().run(),
      superscript: () => editor.chain().focus().toggleSuperscript().run(),
      bulletList: () => editor.chain().focus().toggleBulletList().run(),
      orderedList: () => editor.chain().focus().toggleOrderedList().run(),
      blockquote: () => editor.chain().focus().toggleBlockquote().run(),
      alignLeft: () => editor.chain().focus().setTextAlign("left").run(),
      alignCenter: () => editor.chain().focus().setTextAlign("center").run(),
      alignRight: () => editor.chain().focus().setTextAlign("right").run(),
      link: () => {
        const url = window.prompt("URL")
        if (url) editor.chain().focus().setLink({ href: url }).run()
      },
      table: () =>
        editor.chain().focus().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run(),
      clean: () => editor.chain().focus().clearNodes().unsetAllMarks().run()
    }

    toolbarEl.querySelectorAll("button[data-command]").forEach(btn => {
      btn.addEventListener("click", e => {
        e.preventDefault()
        const cmd = commands[btn.dataset.command]
        if (cmd) cmd()
      })
    })

    const headingSelect = toolbarEl.querySelector('select[data-command="heading"]')
    if (headingSelect) {
      headingSelect.addEventListener("change", () => {
        const value = headingSelect.value
        if (value === "paragraph") {
          editor.chain().focus().setParagraph().run()
        } else {
          editor.chain().focus().toggleHeading({ level: parseInt(value, 10) }).run()
        }
      })
    }
  },

  updateToolbarState(toolbarEl) {
    const editor = this.editor
    const activeMap = {
      bold: editor.isActive("bold"),
      italic: editor.isActive("italic"),
      underline: editor.isActive("underline"),
      strike: editor.isActive("strike"),
      subscript: editor.isActive("subscript"),
      superscript: editor.isActive("superscript"),
      bulletList: editor.isActive("bulletList"),
      orderedList: editor.isActive("orderedList"),
      blockquote: editor.isActive("blockquote"),
      alignLeft: editor.isActive({ textAlign: "left" }),
      alignCenter: editor.isActive({ textAlign: "center" }),
      alignRight: editor.isActive({ textAlign: "right" }),
      link: editor.isActive("link")
    }

    toolbarEl.querySelectorAll("button[data-command]").forEach(btn => {
      const isActive = activeMap[btn.dataset.command]
      btn.classList.toggle("is-active", !!isActive)
    })

    const headingSelect = toolbarEl.querySelector('select[data-command="heading"]')
    if (headingSelect) {
      const level = [1, 2, 3].find(l => editor.isActive("heading", { level: l }))
      headingSelect.value = level ? String(level) : "paragraph"
    }
  }
}

export default RichTextEditor