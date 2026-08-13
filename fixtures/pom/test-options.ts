import { test as base, mergeTests, request } from '@playwright/test';
import { test as pageObjectFixture } from './page-object-fixture';
import { test as apiRequestFixture } from '../api/api-request-fixture';
import { test as helperFixture } from '../helper/helper-fixture';

const test = mergeTests(pageObjectFixture, apiRequestFixture, helperFixture);

const expect = base.expect;
export { test, expect, request };
