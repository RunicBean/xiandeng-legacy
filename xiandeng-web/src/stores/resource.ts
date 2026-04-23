import { getWording } from '@/api/request/system'
import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useResourceStore = defineStore('resource', () => {

    const entityTypeWordingMap = ref()
    const updateEntityTypeWordingMap = async () => {
        
        if (entityTypeWordingMap.value) return
        const data = await getWording('entitytype')
        entityTypeWordingMap.value = data
        
    }
    return {
        entityTypeWordingMap,
        updateEntityTypeWordingMap
    }
})