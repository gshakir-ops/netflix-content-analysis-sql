# Golam Shakir Portfolio — Editing & Customization Guide

## 🎯 Quick Overview

Your portfolio is built with:
- **Single HTML file** (`index.html`)
- **Inline CSS** (all styling in one file)
- **Three.js** (persistent 3D scene in background)
- **Responsive design** (works on all devices)

---

## ⚠️ CRITICAL RULES — DO NOT BREAK THESE

### 🔒 The 3D Foundation is LOCKED

**DO NOT touch:**
- `<div class="stage-3d">` and all content inside
- `<canvas id="three-canvas"></canvas>`
- Any JavaScript code containing `THREE.Scene`
- The `<script>` section with Three.js animation

**WHY?** The 3D man walking through the door is the visual identity. Breaking it ruins the entire portfolio aesthetic.

### 📍 Content Layers are Separate

Your portfolio has **two distinct layers**:

1. **Fixed 3D Layer** (background, doesn't move)
   - Located: `<div class="stage-3d">...</div>`
   - Z-index: 1-2
   - DO NOT MODIFY

2. **Scrolling Content Layer** (text, sections, projects)
   - Located: `<div class="content-layer">...</div>`
   - Z-index: 10+
   - **THIS IS WHAT YOU EDIT**

---

## 📂 File Structure

```
C:\Users\LENOVO\Desktop\vs code\
├── index.html                          (← Main portfolio file)
├── vercel.json                         (← Deployment config)
└── projects/
    ├── amazon-dashboard.html           (Project detail page)
    ├── ecommerce-dashboard.html        (Project detail page)
    ├── excel-automation.html           (Project detail page)
    └── [other files...]
```

---

## 🔍 Understanding the HTML Structure

### The Main Sections

Your portfolio is organized into these sections inside `<div class="content-layer">`:

```html
<!-- HERO SECTION -->
<section class="section hero-section">
  <!-- Your main headline and CTA -->
</section>

<!-- ABOUT SECTION -->
<section id="about" class="section about-section fade-in-section">
  <!-- About content -->
</section>

<!-- SKILLS SECTION -->
<section id="skills" class="section fade-in-section">
  <!-- Skills grid -->
</section>

<!-- WORKFLOW SECTION -->
<section class="section workflow-section fade-in-section">
  <!-- 5-step analytical workflow -->
</section>

<!-- PROJECTS SECTION -->
<section id="projects" class="section projects-section fade-in-section">
  <!-- Project cards -->
</section>

<!-- CONTACT SECTION -->
<section id="contact" class="section contact-section fade-in-section">
  <!-- Contact information -->
</section>
```

### Key CSS Classes

| Class | Purpose | Edit? |
|-------|---------|-------|
| `.section` | Base section styling | ✅ Can adjust padding/margins |
| `.section-title` | Section headings | ✅ Can adjust font size |
| `.section-text` | Paragraph text | ✅ Can adjust color |
| `.skill-card` | Skill boxes | ✅ Can modify styling |
| `.project-card` | Project boxes | ✅ Can modify styling |
| `.workflow-step` | Workflow steps | ✅ Can modify styling |
| `.nav-header` | Navigation bar | ✅ Can modify styling |
| `.stage-3d` | 3D foundation | ❌ DO NOT TOUCH |

---

## ✏️ How to Edit Different Elements

### 1️⃣ EDITING TEXT CONTENT (EASIEST)

**To change any text without breaking styling:**

Find the section you want to edit. For example, to change the About section:

```html
<section id="about" class="section about-section fade-in-section">
  <div class="section-inner">
    <h2 class="section-title">About</h2>
    <p class="section-text">
      ← EDIT THIS TEXT ← Replace with your new text
    </p>
    <p class="section-text">
      ← EDIT THIS TEXT TOO ← Replace with your new text
    </p>
  </div>
</section>
```

**Keep the HTML structure intact:**
```html
<p class="section-text">Your new text here</p>
```

Don't remove the `<p>` tag or change the `class="section-text"` attribute.

---

### 2️⃣ ADDING A NEW SECTION

**To add a completely new section (e.g., "Experience" or "Certifications"):**

1. **Find where to insert it** in the content layer
   - Add it BEFORE `</div>` that closes `<div class="content-layer">`

2. **Copy this template:**

```html
<!-- NEW SECTION TEMPLATE -->
<section id="new-section" class="section fade-in-section">
  <div class="section-inner">
    <h2 class="section-title">Section Title Here</h2>
    <p class="section-text">
      Your content goes here.
    </p>
  </div>
</section>
```

3. **Update the navigation** to link to it:

Find `.nav-links` and add:
```html
<li><a href="#new-section" class="nav-link">New Section</a></li>
```

**Important:**
- Keep `class="section fade-in-section"` (ensures smooth fade-in animation)
- Give it a unique `id` (the `#new-section` part)
- Add to navigation if you want it in the menu

---

### 3️⃣ ADDING A NEW SKILL

**To add a skill to the Core Skills section:**

Find the skills grid:
```html
<div class="skills-grid">
  <!-- Skills appear here -->
</div>
```

Add a new skill card:
```html
<div class="skill-card">
  <div class="skill-name">Tableau</div>
  <div class="skill-level">Dashboard visualization and analytics</div>
</div>
```

**The grid will automatically adjust** the layout — don't worry about spacing.

---

### 4️⃣ ADDING A NEW PROJECT

**To add a 4th project (if you build one):**

Find `<div class="projects-grid">` and add:

```html
<a href="projects/your-project-name.html" style="text-decoration: none; color: inherit;">
  <div class="project-card">
    <h3 class="project-title">Your Project Title</h3>
    <p class="project-description">
      Brief description of what you analyzed and found.
    </p>
    <div class="project-tags">
      <span class="project-tag">Tool 1</span>
      <span class="project-tag">Tool 2</span>
      <span class="project-tag">Tool 3</span>
    </div>
  </div>
</a>
```

Then create the project detail page at `projects/your-project-name.html`.

---

### 5️⃣ CHANGING COLORS

**All colors are defined at the top of the `<style>` section:**

```css
:root {
  --primary-light: #F5F5F0;        /* Off-white text */
  --primary-muted: rgba(245, 245, 240, 0.68);  /* Gray text */
  --primary-faint: rgba(245, 245, 240, 0.58);  /* Lighter gray */
  --accent: #4A9FFF;               /* Blue highlights */
  --bg-dark: #050505;              /* Black background */
}
```

**To change a color:**
1. Find the variable you want to change
2. Replace the color value (e.g., `#F5F5F0` → `#FFFFFF`)
3. It will automatically update everywhere that variable is used

**Don't change colors randomly.** Keep the professional dark theme.

---

### 6️⃣ CHANGING FONTS

**Current font:** `Manrope` (from Google Fonts)

To change it:
1. Find: `<link href="https://fonts.googleapis.com/css2?family=Manrope:wght@200..800&display=swap" rel="stylesheet">`
2. Replace `Manrope` with another Google Font (e.g., `Inter`, `Poppins`, `Lato`)
3. Update the CSS: `font-family: 'Manrope'` → `font-family: 'Your-Font'`

**Recommended fonts for professional portfolios:**
- Inter
- Poppins
- Lato
- Work Sans
- DM Sans

---

### 7️⃣ ADJUSTING SPACING & SIZING

**Section spacing** (padding between sections):
```css
.section {
  min-height: 100vh;
  padding: 0 6vw;        ← Change this to adjust horizontal padding
  display: flex;
  align-items: center;
  position: relative;
}
```

**Headline size** (responsive):
```css
.section-title {
  font-size: clamp(36px, 4.5vw, 56px);
  ↑ min    ↑ responsive  ↑ max
```

To make headlines bigger: `clamp(48px, 6vw, 72px)`
To make them smaller: `clamp(28px, 3.5vw, 42px)`

---

### 8️⃣ ADDING ANIMATIONS

**Existing animations:**
- Fade-in on scroll: `class="fade-in-section"`
- Entrance animation: `@keyframes fadeInUp`

**To animate a new element:**

1. Add the class to your element:
```html
<p class="section-text fade-in-on-scroll">Animated text</p>
```

2. The CSS already handles it — no code needed!

---

## 🚀 How to Update and Deploy

### Step 1: Edit Your Local File

Open `C:\Users\LENOVO\Desktop\vs code\index.html` in a code editor:
- VS Code (recommended)
- Sublime Text
- Notepad++ (not recommended — basic)

### Step 2: Test Locally

Open the website at:
```
http://localhost:3000
```

If the server isn't running:
```bash
cd "C:\Users\LENOVO\Desktop\vs code"
npx serve -p 3000
```

### Step 3: Check for Errors

1. Open browser DevTools: `F12` or `Right-click → Inspect`
2. Go to **Console** tab
3. Look for red errors
4. If there are errors, check your HTML syntax

### Step 4: Deploy to Vercel

When everything looks good locally:

```bash
cd "C:\Users\LENOVO\Desktop\vs code"
vercel --prod
```

Your changes will be live at:
```
https://golam-shakir-portfolio.vercel.app
```

---

## 🛡️ Common Mistakes to Avoid

### ❌ Mistake 1: Breaking HTML Tags

**WRONG:**
```html
<p class="section-text">
  Your text</p>  ← Missing closing tag!
```

**RIGHT:**
```html
<p class="section-text">
  Your text
</p>
```

### ❌ Mistake 2: Changing the 3D Section

**NEVER do this:**
```html
<!-- NEVER EDIT THIS -->
<div class="stage-3d">
  <canvas id="three-canvas"></canvas>
  <div class="video-layer">...</div>
</div>
```

### ❌ Mistake 3: Removing CSS Classes

**WRONG:**
```html
<div class="skill-card">  ← If you remove the class,
  styling breaks!
</div>
```

**RIGHT:**
```html
<div class="skill-card">
  Keep the class!
</div>
```

### ❌ Mistake 4: Not Matching Indentation

Code is easier to read with proper indentation. Your editor should handle this automatically.

### ❌ Mistake 5: Changing Quotes

**WRONG:**
```html
<a href='projects/file.html'>  ← Single quotes can break things
```

**RIGHT:**
```html
<a href="projects/file.html">  ← Double quotes
```

---

## 📋 Quick Reference Checklist

When adding or editing content:

- [ ] I did NOT touch the `<div class="stage-3d">` section
- [ ] I kept all HTML tags properly closed
- [ ] I kept all CSS class names intact
- [ ] I tested locally at http://localhost:3000
- [ ] I checked the browser console for errors (F12)
- [ ] I verified the 3D scene still displays correctly
- [ ] I tested on mobile (right-click → Inspect → Toggle device toolbar)
- [ ] I ran `vercel --prod` to deploy

---

## 🆘 Troubleshooting

### Problem: Website looks broken after editing

**Solution:**
1. Check browser console for errors (F12)
2. Verify you didn't break any HTML tags
3. Make sure you kept CSS class names intact
4. Reload the page (Ctrl+Shift+R for hard refresh)

### Problem: Text styling looks weird

**Solution:**
1. Make sure your text is inside the correct `<p>` or heading tag
2. Check that the class name is correct (e.g., `class="section-text"`)
3. Verify you didn't accidentally delete CSS

### Problem: 3D scene disappeared

**Solution:**
1. You probably edited the 3D section by mistake
2. Revert your changes (Ctrl+Z in your editor)
3. DO NOT edit anything inside `<div class="stage-3d">`

### Problem: New section doesn't animate

**Solution:**
Make sure you added: `class="fade-in-section"` to your section element.

---

## 📖 File Editing Best Practices

### Best Code Editor: VS Code

Download: https://code.visualstudio.com

**Why?**
- Syntax highlighting
- Auto-indentation
- Find & replace (Ctrl+H)
- Live preview extensions available

### How to Open Your File in VS Code

1. Open VS Code
2. File → Open Folder
3. Navigate to: `C:\Users\LENOVO\Desktop\vs code`
4. Click `index.html` to open it

### Useful VS Code Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+F | Find text |
| Ctrl+H | Find & replace |
| Ctrl+S | Save file |
| Ctrl+Z | Undo |
| Ctrl+Y | Redo |
| Alt+Up/Down | Move line up/down |

---

## 🎓 Learning Path

If you want to learn more:

1. **HTML Basics**: https://www.w3schools.com/html/
2. **CSS Styling**: https://www.w3schools.com/css/
3. **Responsive Design**: https://www.w3schools.com/css/css_rwd_intro.asp
4. **Deployment**: Vercel docs at https://vercel.com/docs

---

## 💡 Ideas for Future Enhancements

Things you can safely add:

### 1. New Section: Experience
```html
<section id="experience" class="section fade-in-section">
  <div class="section-inner">
    <h2 class="section-title">Experience</h2>
    <!-- List of projects, simulations, or work -->
  </div>
</section>
```

### 2. New Section: Certifications
```html
<section id="certifications" class="section fade-in-section">
  <div class="section-inner">
    <h2 class="section-title">Certifications</h2>
    <!-- List certifications -->
  </div>
</section>
```

### 3. Add Blog/Articles Link
Link to Medium, Substack, or blog articles

### 4. Add Case Study Downloads
Let visitors download PDF case studies of your projects

### 5. Testimonials Section
Add quotes from colleagues or mentors (authentic only)

---

## 📞 When to Ask for Help

Ask for help if you need to:
- Modify the 3D scene (don't — it's locked!)
- Add complex JavaScript functionality
- Integrate with external APIs
- Significantly redesign the layout
- Add payment/login systems

For simple edits (text, colors, adding sections), follow this guide!

---

## ✅ Summary

**You CAN edit:**
- Text content in any section
- Colors (in the CSS variables)
- Add new sections
- Add skills or projects
- Adjust spacing and sizing
- Change fonts

**You CANNOT edit:**
- The 3D foundation (3D scene, Three.js code)
- The fixed background layer
- The overall two-layer architecture

**To deploy changes:**
```bash
cd "C:\Users\LENOVO\Desktop\vs code"
vercel --prod
```

---

**Your portfolio is yours to customize safely!** 🎉

Follow this guide, and you can confidently make updates without breaking anything.
