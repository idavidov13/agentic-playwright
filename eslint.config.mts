import tseslint from '@typescript-eslint/eslint-plugin';
import tsParser from '@typescript-eslint/parser';
import prettierPlugin from 'eslint-plugin-prettier';
import playwright from 'eslint-plugin-playwright';

/**
 * Prettier configuration for consistent code formatting.
 */
const prettierConfig = {
    semi: true,
    tabWidth: 4,
    useTabs: false,
    printWidth: 80,
    singleQuote: true,
    trailingComma: 'es5',
    bracketSpacing: true,
    arrowParens: 'always',
    proseWrap: 'preserve',
};

/**
 * Extract recommended rules from plugins with proper typing.
 * Plugin config objects are typed loosely; we narrow to a rules record.
 */
type PluginConfig = { rules?: Record<string, unknown> };

const tsRecommendedRules =
    (tseslint.configs?.recommended as PluginConfig)?.rules ?? {};

const playwrightRecommendedRules =
    (playwright.configs?.['flat/recommended'] as PluginConfig)?.rules ?? {};

/**
 * ESLint flat configuration for the Agentic Playwright project.
 * Uses TypeScript, Prettier, and Playwright plugins for comprehensive linting.
 */
const config = [
    {
        ignores: ['node_modules', 'dist', 'playwright-report', 'test-results'],
    },
    {
        files: ['**/*.ts', '**/*.tsx'],
        languageOptions: {
            parser: tsParser,
            parserOptions: {
                ecmaVersion: 2020,
                sourceType: 'module',
                project: ['./tsconfig.json'],
                tsconfigRootDir: __dirname,
            },
        },
        plugins: {
            '@typescript-eslint': tseslint,
            prettier: prettierPlugin,
            playwright,
        },
        rules: {
            ...tsRecommendedRules,
            ...playwrightRecommendedRules,

            // Prettier integration
            'prettier/prettier': ['error', prettierConfig],

            // TypeScript strict rules
            '@typescript-eslint/explicit-function-return-type': 'error',
            '@typescript-eslint/no-explicit-any': 'error',
            '@typescript-eslint/no-unused-vars': [
                'error',
                { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
            ],
            '@typescript-eslint/no-inferrable-types': 'error',
            '@typescript-eslint/no-empty-function': 'error',
            '@typescript-eslint/no-floating-promises': 'error',

            // General JavaScript rules
            'no-console': 'error',
            'prefer-const': 'error',

            // Playwright-specific rules - Constitution enforcement
            'playwright/missing-playwright-await': 'error',
            'playwright/no-page-pause': 'error',
            'playwright/no-useless-await': 'error',
            'playwright/no-skipped-test': 'error',

            // Additional Playwright rules for Constitution compliance
            'playwright/no-wait-for-timeout': 'error', // WON'T: No Hard Waits
            'playwright/no-force-option': 'warn', // Prefer natural interactions
            'playwright/prefer-web-first-assertions': 'error', // MUST: Web-first assertions
            'playwright/no-raw-locators': 'warn', // MUST: Prefer semantic locators
            'playwright/no-useless-not': 'error', // Clean assertions
            'playwright/no-nth-methods': 'warn', // Avoid brittle nth selectors
            'playwright/prefer-lowercase-title': 'warn', // Consistent test naming
            'playwright/prefer-to-be': 'error', // Use toBe over toEqual for primitives
            'playwright/prefer-to-have-length': 'error', // Cleaner length assertions
            'playwright/require-top-level-describe': 'error', // Organized test structure
            'playwright/expect-expect': 'error', // Tests must have assertions
            'playwright/no-conditional-in-test': 'warn', // Avoid flaky conditionals
            'playwright/no-eval': 'error', // Security: no eval in tests
            'playwright/valid-expect': 'error', // Valid expect usage
            'playwright/no-focused-test': 'error', // No test.only in commits
            'playwright/no-standalone-expect': 'error', // Expect must be in test
        },
    },
];

export default config;
