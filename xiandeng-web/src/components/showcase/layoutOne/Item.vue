<script setup lang="ts">
defineProps([
    "imageLink",
    "imageUrl",
    "title"
])
</script>

<template>
    <a :href="imageLink">
      <div class="flex flex-col justify-between items-center space-y-1">
        <img :src="imageUrl" alt="">
        <div class="text-sm font-bold text-gray-600">{{title}}</div>
      </div>
    </a>
</template>

<style scoped>
.item-container {
    padding: 15px 8px;
}
img {
    width: 40%;
}

h1 {
    color: #1a1a1a;
    font-size: 14px;
}
</style>