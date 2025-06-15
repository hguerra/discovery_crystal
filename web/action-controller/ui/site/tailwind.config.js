/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./*.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      backgroundImage: {
        'vestibular': "url('/imgs/vestibular.jpg')",
      }
    },
  },
  daisyui: {
    themes: [
      {
        quero: {
        "primary": "#304FFE",
        "secondary": "#FA6400",
        "accent": "#8A3FFC",
        "neutral": "#2b3440",
        "base-100": "#ffffff",
        "info": "#3abff8",
        "success": "#36d399",
        "warning": "#fbbd23",
        "error": "#f87272",
      },
    },
  ],
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/aspect-ratio'),
    require("daisyui"),
  ],
}
