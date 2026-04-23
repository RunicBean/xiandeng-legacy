
<script setup lang="ts">
import { onMounted } from 'vue';
onMounted(() => {
    // console.log(window.location.host);
    
    // var obj = new WxLogin({
    //     self_redirect:true,
    //     id:"login_container", 
    //     appid: "wx38b8619f87bcf054", 
    //     scope: "snsapi_login", 
    //     redirect_uri: encodeURIComponent("https://"+window.location.host+"/"), 
    //     state: Math.ceil(Math.random()*1000), 
    //     style: "black",
    //     href: ""
    // });
})



</script>

<template>
    <div>
        <div id="login_container"></div>
    </div>
</template>

<style scoped>

</style>