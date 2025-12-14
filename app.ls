// ------------------ Translations ------------------
const translations = {
  en: {
    appTitle: "My Recipe App",
    appSubtitle: "Store recipes and see what you can cook with your ingredients.",
    pantryTitle: "Ingredients I Have",
    ingredientPlaceholder: "Add ingredient",
    addIngredientButton: "Add",
    clearIngredients: "Clear all ingredients",
    addRecipeTitle: "Add Recipe",
    recipeNameLabel: "Recipe name",
    ingredientsLabel: "Ingredients (comma separated)",
    instructionsLabel: "Instructions",
    categoryLabel: "Category",
    timeLabel: "Time (min)",
    imageUrlLabel: "Image URL (optional)",
    saveRecipeButton: "Save Recipe",
    recipesTitle: "Recipes",
    searchPlaceholder: "Search recipes...",
    filterCookable: "Show only recipes I can cook now",
    filterFavorites: "Favorites only",
    clearRecipes: "Clear all recipes",
    footerNote: "Data is saved only on this device using localStorage.",
    noIngredients: "No ingredients added yet.",
    noRecipes: "No recipes to show yet.",
    badgeCookable: "You can cook this",
    badgeMissing: "Missing ingredients",
    missingLabel: "Missing",
    confirmClearIngredients: "Clear all ingredients from your pantry?",
    confirmClearRecipes: "Delete ALL recipes?",
    confirmDeleteRecipe: "Delete this recipe?",
    favorite: "Favorite",
    unfavorite: "Unfavorite",
    minutesSuffix: "min"
  },
  ar: {
    appTitle: "تطبيق الوصفات",
    appSubtitle: "احفظ وصفاتك واعرف ما يمكنك طبخه بالمكونات المتوفرة لديك.",
    pantryTitle: "المكونات المتوفرة لدي",
    ingredientPlaceholder: "أضف مكوناً",
    addIngredientButton: "إضافة",
    clearIngredients: "مسح جميع المكونات",
    addRecipeTitle: "إضافة وصفة",
    recipeNameLabel: "اسم الوصفة",
    ingredientsLabel: "المكونات (مفصولة بفواصل)",
    instructionsLabel: "طريقة التحضير",
    categoryLabel: "التصنيف",
    timeLabel: "الوقت (بالدقائق)",
    imageUrlLabel: "رابط صورة (اختياري)",
    saveRecipeButton: "حفظ الوصفة",
    recipesTitle: "الوصفات",
    searchPlaceholder: "ابحث عن وصفة...",
    filterCookable: "عرض الوصفات التي يمكنني إعدادها الآن",
    filterFavorites: "المفضلة فقط",
    clearRecipes: "حذف جميع الوصفات",
    footerNote: "يتم حفظ البيانات على هذا الجهاز فقط باستخدام LocalStorage.",
    noIngredients: "لا توجد مكونات مضافة بعد.",
    noRecipes: "لا توجد وصفات لعرضها حالياً.",
    badgeCookable: "يمكنك إعداد هذه الوصفة",
    badgeMissing: "هناك مكونات ناقصة",
    missingLabel: "المكونات الناقصة",
    confirmClearIngredients: "هل تريد مسح جميع المكونات المتوفرة؟",
    confirmClearRecipes: "هل تريد حذف كل الوصفات؟",
    confirmDeleteRecipe: "هل تريد حذف هذه الوصفة؟",
    favorite: "مفضلة",
    unfavorite: "إزالة من المفضلة",
    minutesSuffix: "دقيقة"
  }
};

let currentLang = localStorage.getItem("lang") || "en";

function t(key) {
  return translations[currentLang][key] || translations.en[key] || key;
}

function applyStaticTranslations() {
  document.documentElement.lang = currentLang;
  document.body.classList.toggle("rtl", currentLang === "ar");

  document.querySelectorAll("[data-i18n]").forEach((el) => {
    const key = el.getAttribute("data-i18n");
    el.textContent = t(key);
  });

  document.querySelectorAll("[data-i18n-placeholder]").forEach((el) => {
    const key = el.getAttribute("data-i18n-placeholder");
    el.setAttribute("placeholder", t(key));
  });

  // update language buttons
  document.querySelectorAll(".lang-btn").forEach((btn) => {
    btn.classList.toggle("active", btn.dataset.lang === currentLang);
  });
}

// ------------------ Data storage ------------------
let recipes = [];
let available = [];

// ------------------ Firestore (recipes only) ------------------
const recipesCollection = () => db.collection("recipes");

async function loadRecipesFromCloud() {
  try {
    const snapshot = await recipesCollection().get();
    if (!snapshot.empty) {
      recipes = snapshot.docs.map(doc => doc.data());
      localStorage.setItem("recipes", JSON.stringify(recipes));
    }
  } catch (err) {
    console.warn("Cloud load failed, using local data");
  }
}

async function saveRecipeToCloud(recipe) {
  try {
    await recipesCollection().doc(String(recipe.id)).set(recipe);
  } catch (err) {
    console.warn("Cloud save failed");
  }
}

async function deleteRecipeFromCloud(id) {
  try {
    await recipesCollection().doc(String(id)).delete();
  } catch (err) {
    console.warn("Cloud delete failed");
  }
}

function loadData() {
  try {
    recipes = JSON.parse(localStorage.getItem("recipes") || "[]");
loadRecipesFromCloud();
available = JSON.parse(localStorage.getItem("available") || "[]");
  } catch {
    recipes = [];
    available = [];
  }
}

function saveData() {
  localStorage.setItem("recipes", JSON.stringify(recipes));
  localStorage.setItem("available", JSON.stringify(available));
}

// ------------------ Helpers ------------------
function normalizeIngredient(name) {
  return name.trim().toLowerCase();
}

function canMakeRecipe(recipe) {
  return recipe.ingredients.every((ing) => available.includes(ing));
}

function missingIngredients(recipe) {
  return recipe.ingredients.filter((ing) => !available.includes(ing));
}

function getSearchTerm() {
  const el = document.getElementById("searchInput");
  return el ? el.value.trim().toLowerCase() : "";
}

// ------------------ Render functions ------------------
function renderAvailable() {
  const list = document.getElementById("availableList");
  if (!list) return;

  if (available.length === 0) {
    list.innerHTML = `<li style="font-size:0.85rem;color:#777;">${t(
      "noIngredients"
    )}</li>`;
    return;
  }

  list.innerHTML = available
    .map(
      (ing, index) => `
        <li class="pill">
          <span>${ing}</span>
          <button class="pill-remove" type="button" data-index="${index}">×</button>
        </li>
      `
    )
    .join("");
}

function renderRecipes() {
  const container = document.getElementById("recipesList");
  const filterCookable = document.getElementById("filterCookable");
  const filterFavorites = document.getElementById("filterFavorites");
  if (!container) return;

  const onlyCookable = filterCookable?.checked;
  const onlyFavorites = filterFavorites?.checked;
  const search = getSearchTerm();

  let visible = recipes.slice();

  if (search) {
    visible = visible.filter((r) => {
      const inName = r.name.toLowerCase().includes(search);
      const inIngredients = r.ingredients.some((i) =>
        i.toLowerCase().includes(search)
      );
      return inName || inIngredients;
    });
  }

  if (onlyCookable) {
    visible = visible.filter(canMakeRecipe);
  }

  if (onlyFavorites) {
    visible = visible.filter((r) => r.favorite);
  }

  if (visible.length === 0) {
    container.innerHTML = `<p style="font-size:0.9rem;color:#777;">${t(
      "noRecipes"
    )}</p>`;
    return;
  }

  container.innerHTML = visible
    .map((r) => {
      const canMake = canMakeRecipe(r);
      const missing = missingIngredients(r);
      const metaParts = [];
      if (r.category) metaParts.push(r.category);
      if (r.time) metaParts.push(`${r.time} ${t("minutesSuffix")}`);

      const metaStr = metaParts.join(" • ");

      const imgHTML = r.imageUrl
        ? `<img src="${r.imageUrl}" class="recipe-thumb" alt="">`
        : `<div class="recipe-thumb"></div>`;

      const badgeHTML = canMake
        ? `<span class="badge">${t("badgeCookable")}</span>`
        : `<span class="badge badge-warning">${t("badgeMissing")}</span>`;

      const missingHTML =
        !canMake && missing.length
          ? `<p class="recipe-missing"><strong>${t(
              "missingLabel"
            )}:</strong> ${missing.join(", ")}</p>`
          : "";

      const favClass = r.favorite ? "favorite-btn favorited" : "favorite-btn";
      const favLabel = r.favorite ? t("unfavorite") : t("favorite");
      const star = r.favorite ? "★" : "☆";

      return `
        <article class="recipe-card" data-id="${r.id}">
          ${imgHTML}
          <div class="recipe-body">
            <div class="recipe-header">
              <div>
                <h3 class="recipe-title">${r.name}</h3>
                <p class="recipe-meta">
                  ${metaStr}
                  ${metaStr ? "" : ""}
                  ${badgeHTML}
                </p>
              </div>
            </div>

            <p class="recipe-ingredients">
              <strong>${translations[currentLang].ingredientsLabel}:</strong>
              ${r.ingredients.join(", ")}
            </p>

            ${missingHTML}

            ${
              r.instructions
                ? `<p style="font-size:0.85rem;margin:0.25rem 0;">
                    <strong>${t("instructionsLabel")}:</strong> ${r.instructions}
                   </p>`
                : ""
            }

            <div class="recipe-actions">
              <button type="button" class="${favClass}">
                <span class="star">${star}</span>
                <span>${favLabel}</span>
              </button>
              <button type="button" class="secondary small delete-recipe">
                🗑
              </button>
            </div>
          </div>
        </article>
      `;
    })
    .join("");
}

// ------------------ Event listeners ------------------
function setupEventListeners(const toggleCookableBtn = document.getElementById("toggleCookable");

if (toggleCookableBtn && filterCookable) {
  toggleCookableBtn.addEventListener("click", () => {
    filterCookable.checked = !filterCookable.checked;

    toggleCookableBtn.textContent = filterCookable.checked
      ? "Show all recipes"
      : "Show cookable only";

    renderRecipes();
  });
}) {
  const addIngredientForm = document.getElementById("add-ingredient-form");
  const ingredientInput = document.getElementById("ingredientInput");
  const clearIngredientsBtn = document.getElementById("clear-ingredients");
  const availableList = document.getElementById("availableList");

  const addRecipeForm = document.getElementById("add-recipe-form");
  const recipesList = document.getElementById("recipesList");
  const clearRecipesBtn = document.getElementById("clear-recipes");
  const filterCookable = document.getElementById("filterCookable");
  const filterFavorites = document.getElementById("filterFavorites");
  const searchInput = document.getElementById("searchInput");

  // Language toggle
  document.querySelectorAll(".lang-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      const lang = btn.dataset.lang;
      if (lang && lang !== currentLang) {
        currentLang = lang;
        localStorage.setItem("lang", currentLang);
        applyStaticTranslations();
        renderAvailable();
        renderRecipes();
      }
    });
  });

  // Add ingredient
  if (addIngredientForm && ingredientInput) {
    addIngredientForm.addEventListener("submit", (e) => {
      e.preventDefault();
      const raw = ingredientInput.value;
      const ing = normalizeIngredient(raw);
      if (!ing) return;
      if (!available.includes(ing)) {
        available.push(ing);
        saveData();
        renderAvailable();
        renderRecipes();
      }
      ingredientInput.value = "";
      ingredientInput.focus();
    });
  }

  // Remove ingredient (delegation)
  if (availableList) {
    availableList.addEventListener("click", (e) => {
      const target = e.target;
      if (target.classList.contains("pill-remove")) {
        const index = Number(target.dataset.index);
        if (!Number.isNaN(index)) {
          available.splice(index, 1);
          saveData();
          renderAvailable();
          renderRecipes();
        }
      }
    });
  }

  // Clear ingredients
  if (clearIngredientsBtn) {
    clearIngredientsBtn.addEventListener("click", () => {
      if (
        available.length > 0 &&
        confirm(t("confirmClearIngredients"))
      ) {
        available = [];
        saveData();
        renderAvailable();
        renderRecipes();
      }
    });
  }

  // Add recipe
  if (addRecipeForm) {
    addRecipeForm.addEventListener("submit", (e) => {
      e.preventDefault();

      const nameEl = document.getElementById("recipeName");
      const ingredientsEl = document.getElementById("recipeIngredients");
      const instructionsEl = document.getElementById("recipeInstructions");
      const categoryEl = document.getElementById("recipeCategory");
      const timeEl = document.getElementById("recipeTime");
      const imageEl = document.getElementById("recipeImage");

      const name = nameEl.value.trim();
      const ingredients = ingredientsEl.value
        .split(",")
        .map(normalizeIngredient)
        .filter((x) => x.length > 0);
      const instructions = instructionsEl.value.trim();
      const category = categoryEl.value.trim();
      const time = timeEl.value ? Number(timeEl.value) : null;
      const imageUrl = imageEl.value.trim();

      if (!name || ingredients.length === 0) {
        alert(
          currentLang === "ar"
            ? "من فضلك أدخل اسم الوصفة ومكوناً واحداً على الأقل."
            : "Please enter a recipe name and at least one ingredient."
        );
        return;
      }

recipes.push({
  id: Date.now(),
  name,
  ingredients,
  instructions,
  category,
  time,
  imageUrl,
  favorite: false
});

saveRecipeToCloud(recipes[recipes.length - 1]);
saveData();

      nameEl.value = "";
      ingredientsEl.value = "";
      instructionsEl.value = "";
      categoryEl.value = "";
      timeEl.value = "";
      imageEl.value = "";

      renderRecipes();
    });
  }

  // Recipes list events: favorite + delete (delegation)
  if (recipesList) {
    recipesList.addEventListener("click", (e) => {
      const target = e.target;
      const card = target.closest(".recipe-card");
      if (!card) return;
      const id = Number(card.dataset.id);
      const recipe = recipes.find((r) => r.id === id);
      if (!recipe) return;

      if (
        target.classList.contains("delete-recipe") ||
        target.closest(".delete-recipe")
      ) {
        if (confirm(t("confirmDeleteRecipe"))) {
recipes = recipes.filter((r) => r.id !== id);
deleteRecipeFromCloud(id);
saveData();
renderRecipes();
        }
      } else if (
        target.classList.contains("favorite-btn") ||
        target.closest(".favorite-btn")
      ) {
        recipe.favorite = !recipe.favorite;
        saveData();
        renderRecipes();
      }
    });
  }

  // Filters
  if (filterCookable) {
    filterCookable.addEventListener("change", renderRecipes);
  }
  if (filterFavorites) {
    filterFavorites.addEventListener("change", renderRecipes);
  }
  if (searchInput) {
    searchInput.addEventListener("input", () => {
      renderRecipes();
    });
  }

  // Clear all recipes
  if (clearRecipesBtn) {
    clearRecipesBtn.addEventListener("click", () => {
      if (recipes.length > 0 && confirm(t("confirmClearRecipes"))) {
        recipes = [];
        saveData();
        renderRecipes();
      }
    });
  }
}

// ------------------ PWA: service worker ------------------
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker
      .register("./service-worker.js")
      .catch((err) => console.error("SW registration failed:", err));
  });
}

// ------------------ Init ------------------
document.addEventListener("DOMContentLoaded", () => {
  loadData();
  applyStaticTranslations();
  setupEventListeners();
  renderAvailable();
  renderRecipes();
});