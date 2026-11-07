<script setup lang="ts">
import Child from './Child.vue';

const count = 1;
function increment(step: number): number {
  return count + step;
}
const label: string = increment(1);
</script>

<template>
  <Child :value="increment(count)" />
  <p>{{ label }}</p>
</template>
