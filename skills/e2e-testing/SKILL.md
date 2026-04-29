---
name: e2e-testing
description: Patterns Playwright pour tests E2E maintenables — Page Object Model, fixtures, auth state, tests parallèles, debugging. À utiliser avant chaque sprint de tests E2E ou onboarding.
---

# E2E Testing

## Quand utiliser

- Setup initial de Playwright sur un nouveau projet
- Écriture de nouveaux tests E2E
- Refactor de tests existants devenus fragiles
- Debug d'un test flaky

## Setup

### Installation

```bash
pnpm create playwright@latest
# Choisir : TypeScript, tests/e2e, GitHub Actions
```

### Config recommandée

```ts
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI ? 'github' : 'html',
  
  use: {
    baseURL: process.env.E2E_BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    locale: 'fr-CH',
    timezoneId: 'Europe/Zurich'
  },
  
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'mobile', use: { ...devices['iPhone 14'] } }
  ],
  
  webServer: process.env.CI ? undefined : {
    command: 'pnpm dev',
    url: 'http://localhost:3000',
    reuseExistingServer: true
  }
})
```

## Page Object Model

```
tests/e2e/
├── pages/
│   ├── base.page.ts          # superclass
│   ├── login.page.ts
│   └── dashboard.page.ts
├── fixtures/
│   ├── auth.ts               # auth state setup
│   └── test-data.ts
├── flows/
│   ├── login.spec.ts
│   ├── checkout.spec.ts
│   └── quote-submission.spec.ts
└── playwright.config.ts
```

### Base page

```ts
// tests/e2e/pages/base.page.ts
import { Page, expect } from '@playwright/test'

export class BasePage {
  constructor(protected page: Page) {}
  
  async expectNoErrors() {
    await expect(this.page.getByRole('alert')).not.toBeVisible()
  }
  
  async waitForToast(text: string | RegExp) {
    await expect(this.page.getByRole('status')).toContainText(text)
  }
}
```

### Page concrète

```ts
// tests/e2e/pages/login.page.ts
import { Page, Locator, expect } from '@playwright/test'
import { BasePage } from './base.page'

export class LoginPage extends BasePage {
  readonly emailInput: Locator
  readonly passwordInput: Locator
  readonly submitBtn: Locator
  
  constructor(page: Page) {
    super(page)
    this.emailInput = page.getByLabel(/email/i)
    this.passwordInput = page.getByLabel(/mot de passe/i)
    this.submitBtn = page.getByRole('button', { name: /se connecter/i })
  }
  
  async goto() {
    await this.page.goto('/login')
  }
  
  async login(email: string, password: string) {
    await this.emailInput.fill(email)
    await this.passwordInput.fill(password)
    await this.submitBtn.click()
  }
}
```

## Auth state (réutilisée entre tests)

```ts
// tests/e2e/fixtures/auth.ts
import { test as base } from '@playwright/test'
import { LoginPage } from '../pages/login.page'

export const test = base.extend({
  authenticatedPage: async ({ browser }, use) => {
    const context = await browser.newContext({
      storageState: 'tests/e2e/.auth/user.json'
    })
    const page = await context.newPage()
    await use(page)
    await context.close()
  }
})

// tests/e2e/auth.setup.ts
import { test as setup } from '@playwright/test'
import { LoginPage } from './pages/login.page'

setup('authenticate', async ({ page }) => {
  const login = new LoginPage(page)
  await login.goto()
  await login.login('test@example.com', 'password')
  await page.waitForURL('/dashboard')
  await page.context().storageState({ path: 'tests/e2e/.auth/user.json' })
})
```

## Patterns de tests

### Test isolé (setup/teardown propre)

```ts
import { test, expect } from '@playwright/test'

test.describe('Quote submission', () => {
  test.beforeEach(async ({ page }) => {
    // Setup data via API ou DB direct
    await page.request.post('/api/test/seed-quote', {
      data: { artisanEmail: 'artisan@test.com' }
    })
  })
  
  test.afterEach(async ({ page }) => {
    await page.request.delete('/api/test/cleanup')
  })
  
  test('artisan submits a valid quote', async ({ page }) => {
    // ...
  })
})
```

### Tags pour smoke tests

```ts
test('@smoke checkout flow', async ({ page }) => {
  // test critique, lancé en CI à chaque PR
})

test('@regression edge case', async ({ page }) => {
  // lancé en nightly seulement
})
```

```bash
# Run only smoke tests
pnpm playwright test --grep @smoke
```

### Visual regression

```ts
test('homepage screenshot', async ({ page }) => {
  await page.goto('/')
  await expect(page).toHaveScreenshot('homepage.png', {
    maxDiffPixelRatio: 0.01
  })
})
```

## Selectors : du meilleur au pire

```ts
// ✅ Best : par rôle ARIA
page.getByRole('button', { name: 'Submit' })
page.getByLabel('Email')
page.getByPlaceholder('Search...')

// ✅ Good : par texte
page.getByText('Welcome')

// 🟡 OK : test-id (à utiliser quand pas d'autre option)
page.getByTestId('submit-quote-btn')

// ❌ Bad : par classe CSS
page.locator('.btn-primary')

// ❌ Worst : par xpath complexe
page.locator('//div[3]/button[2]')
```

## Anti-patterns

### ❌ `waitForTimeout`

```ts
// ❌ Flaky par construction
await page.click('button')
await page.waitForTimeout(2000)  // pourquoi 2s ? On sait pas
await expect(page.locator('.success')).toBeVisible()

// ✅ Auto-retry intégré
await page.click('button')
await expect(page.getByRole('alert')).toBeVisible()  // retry jusqu'à apparition
```

### ❌ Tests qui dépendent d'autres tests

```ts
test('1. create user', async () => {...})
test('2. login with that user', async () => {...})  // ⚠️ dépend de 1
```
→ Chaque test setup ses propres données.

### ❌ Sélecteurs fragiles

```ts
page.locator('div > div:nth-child(3) > button')  // casse au moindre refactor
```

### ❌ Trop de tests E2E

E2E sont lents et coûteux. Cible :
- 10-20 tests E2E pour les **parcours critiques**
- 100+ tests unitaires/intégration pour le reste

Pyramide inverse = build lent + flakiness élevée.

## Couverture cible (projet type Edirex)

### 🔴 Critique (tests @smoke, run à chaque PR)
- Signup → onboarding → premier état utilisable
- Login + recovery
- Checkout / paiement Stripe
- Soumission de devis (artisan)
- Acceptation de devis (client)

### 🟠 Important (run nightly)
- Filtres + recherche
- Édition profil
- Notifications email triggered

### 🟡 Nice (run avant release)
- Pages marketing, blog
- Mentions légales

## Debug d'un test flaky

```bash
# Run avec UI pour debug visuel
pnpm playwright test --ui

# Run en headed mode
pnpm playwright test --headed --workers=1

# Voir la trace après échec
pnpm playwright show-trace test-results/.../trace.zip

# Repeat un test pour vérifier stabilité
pnpm playwright test login.spec.ts --repeat-each=10
```

Causes courantes de flakiness :
1. **Timing** : `waitForTimeout` en place de retry sur condition
2. **Data** : test depend d'état pré-existant qui change
3. **Réseau** : appel à API tierce sans mock
4. **Race conditions** : deux tests qui utilisent la même data en parallèle
