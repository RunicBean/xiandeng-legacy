<template>
    <div class="">
        <div class="title mt-12 text-2xl text-center"><span>大学生专业规划测评</span></div>
        <div class="steps sm:w-2/3 md:w-1/3 mx-auto mt-8">
            <a-steps v-model:current="active" :responsive="false" label-placement="vertical" size="small" direction="horizontal" :items="steps">
                <!-- <a-step title="测评说明" />
                <a-step title="基本信息" />
                <a-step title="测评" /> -->
            </a-steps>
        </div>
        <div v-show="active == 0" class="notice w-4/5 md:w-2/5 mx-auto mt-12">

            <a-card shadow="always" :body-style="{ padding: '20px', textIndent: '2rem' }">
                <template #title>
                    <div>
                        <span>测评须知</span>
                    </div>
                </template>
                <p>把握未来，从大学开始！</p>
                <p>我们相信，每个大学生都有无限可能，只要给予正确的引导和培养，便能成功拥抱未来。我们不仅提供针对保研、考研、央国企就业、三支一扶、部队文职、选调生和考公务员的多种方案，还针对具体需求量身定制个性化的发展计划，帮助学生从根本上掌握核心竞争力，实现自我价值。</p>
                <p>让我们携手并进，创造美好未来！</p>

                <p>请认真填写院校及专业信息，以便后续进行专业解读。</p>

            </a-card>
            <a-button class="float-end mt-10 mb-10" type="primary" size="default" @click="next()">进入测评</a-button>

        </div>
        <div v-show="active == 1" class="notice w-4/5 md:w-2/5 mx-auto mt-12">
            <a-card shadow="always" :body-style="{ padding: '20px' }">
                <template #title>
                    <div>
                        <span>信息填写</span>
                    </div>
                </template>
                <a-form
                :model="additionalForm"
                ref="additionalFormRef"
                :rules="additionalRules"
                layout="inline"
                size="default">
                    <a-form-item label="学制" name="majorType" class="w-4/5">
                        <a-select
                            v-model:value="additionalForm.majorType"
                            :options="[
                                {label: '专科', value: 'ASSOCIATE'},
                                {label: '本科', value: 'BACHELOR'}
                            ]">
                        </a-select>
                    </a-form-item>
                    <div class="flex">
                        <a-form-item label="姓" class="w-1/3" name="lastname">
                            <a-input v-model:value="additionalForm.lastname"></a-input>
                        </a-form-item>
                        <a-form-item label="名" class="w-1/3" name="firstname">
                            <a-input v-model:value="additionalForm.firstname"></a-input>
                        </a-form-item>
                    </div>
                    <a-form-item label="性别" name="sex">
                        <a-radio-group v-model:value="additionalForm.sex">
                            <a-radio value="1" size="large">男</a-radio>
                            <a-radio value="2" size="large">女</a-radio>
                        </a-radio-group>
                    </a-form-item>
                    <a-form-item label="大学" name="university" class="w-4/5">
                        <a-select v-model:value="additionalForm.university" :options="university" show-search @search="runSearchUniversity">
                        </a-select>
                    </a-form-item>
                    <a-form-item label="入学日期" name="entryDate">
                        <DatePicker v-model="additionalForm.entryDate" />
                    </a-form-item>
                    <a-form-item label="学年（大学/大专的总学习年数）" name="degreeYears">
                        <a-input-number v-model:value="additionalForm.degreeYears" />
                    </a-form-item>
                    <div v-if="additionalForm.majorType == 'BACHELOR'" class="w-4/5">
                        <a-form-item label="专业" name="major" class="w-full">
                            <a-select :filter-option="false" v-model:value="additionalForm.major" :options="bachelorMajors" show-search @search="searchBachelorMajors">
                            </a-select>
                        </a-form-item>
                    </div>
                    <div v-if="additionalForm.majorType == 'ASSOCIATE'" class="w-4/5">
                        <a-form-item label="专业" name="major" class="w-full">
                            <a-select :filter-option="false" v-model:value="additionalForm.major" :options="assoMajors" show-search @search="searchAssociateMajors">
                            </a-select>
                        </a-form-item>
                    </div>
                </a-form>
            </a-card>
            <a-button type="primary" class="float-end mt-10 mb-10" size="default" @click="additionalFormNext()">提交下一步</a-button>

        </div>

        <div v-show="active == 2" class="notice w-4/5 md:w-2/5 mx-auto mt-12">
            <a-card shadow="always" :body-style="{padding: '20px'}">
                <template #title>
                    <div>
                        <span>高考信息</span>
                    </div>
                </template>
                <a-form
                :model="gaokaoForm"
                ref="gaokaoFormRef"
                :rules="gaokaoRules"
                layout="inline"
                size="default"
                class="space-y-2"
                >
                    <a-form-item name="totalScore">
                        <a-input-number class="w-full" v-model:value="gaokaoForm.totalScore" placeholder="总分" />
                    </a-form-item>
                    <a-form-item name="chinese">
                        <a-input-number class="w-full" v-model:value="gaokaoForm.chinese" placeholder="语文" />
                    </a-form-item>
                    <a-form-item name="mathematics">
                        <a-input-number class="w-full" v-model:value="gaokaoForm.mathematics" placeholder="数学" />
                    </a-form-item>
                    <a-form-item name="foreignLanguage">
                        <a-input-number class="w-full" v-model:value="gaokaoForm.foreignLanguage" placeholder="外语" />
                    </a-form-item>
                    <a-form-item name="physics">
                        <a-input-number class="w-full" v-model:value="gaokaoForm.physics" placeholder="物理" />
                    </a-form-item>
                    <a-form-item name="chemistry">
                        <a-input-number class="w-full" v-model:value="gaokaoForm.chemistry" placeholder="化学" />
                    </a-form-item>
                    <a-form-item name="biology">
                        <a-input-number class="w-full" v-model:value="gaokaoForm.biology" placeholder="生物" />
                    </a-form-item>
                    <a-form-item name="politics">
                        <a-input-number class="w-full" v-model:value="gaokaoForm.politics" placeholder="政治" />
                    </a-form-item>
                    <a-form-item name="history">
                        <a-input-number class="w-full" v-model:value="gaokaoForm.history" placeholder="历史" />
                    </a-form-item>
                    <a-form-item name="geography">
                        <a-input-number class="w-full" v-model:value="gaokaoForm.geography" placeholder="地理" />
                    </a-form-item>
                </a-form>
            </a-card>
            <a-button type="primary" class="float-end mt-10 mb-10" size="default" @click="gaokaoFormNext()">提交下一步</a-button>
        </div>

        <div v-show="active == 3" class="notice w-4/5 md:w-2/5 mx-auto mt-12">
            <a-card shadow="always" :body-style="{ padding: '10px' }">
                <template #title>
                    <div>
                        <span>性格测试</span>
                    </div>
                </template>
                <a-form
                label-position="top"
                :model="mbtiForm"
                :rules="mbtiRules"
                ref="mbtiFormRef"
                label-width="80px"
                size="default">
                    <a-form-item label="1. 能量维度-我更倾向于" size="default" name="mbtiEnergy">
                        <a-radio-group v-model:value="mbtiForm.mbtiEnergy" class="ml-1 space-y-3">
                            <a-radio value="E" size="large">
                                <div class="text-pretty"><a-tag class="text-blue-500 font-bold text-lg">E</a-tag> - 将注意力聚集于外部世界和与他人的交往上。例如：聚会、讨论、聊天，通过这些外部交往获得能量</div>
                            </a-radio>

                            <a-radio value="I" size="large">
                                <div class="text-pretty"><a-tag class="text-blue-500 font-bold text-lg">I</a-tag> - 注重自己的内心体验。例如：独立思考，看书</div>
                            </a-radio>
                        </a-radio-group>
                    </a-form-item>

                    <a-divider direction="horizontal" content-position="left"></a-divider>

                    <a-form-item label="2. 关注维度-我更倾向于" size="default" name="mbtiMind">
                        <a-radio-group v-model:value="mbtiForm.mbtiMind" class="ml-1 space-y-3">
                            <a-radio value="S" size="large">
                                <div class="text-pretty"><a-tag class="text-blue-500 font-bold text-lg">S</a-tag> - 关注由感觉器官获取的具体信息：看到的、听到的事物，关注细节、喜欢描述、使用和琢磨已知技能</div>
                            </a-radio>

                            <a-radio value="N" size="large">
                                <div class="text-pretty"><a-tag class="text-blue-500 font-bold text-lg">N</a-tag> - 关注事物的整体和发展变化趋势：灵感、重视想象力，喜欢学新技能，但易喜新厌旧、跳跃思维</div>
                            </a-radio>
                        </a-radio-group>
                    </a-form-item>

                    <a-divider direction="horizontal" content-position="left"></a-divider>

                    <a-form-item label="3. 决定维度-我更倾向于" size="default" class="text-wrap" name="mbtiDecision">
                        <a-radio-group v-model:value="mbtiForm.mbtiDecision" class="ml-1 space-y-3">
                            <a-radio value="T" size="large">
                                <div class="text-pretty"><a-tag class="text-blue-500 font-bold text-lg">T</a-tag> - 重视逻辑关系，喜欢通过客观分析作决定评价。例如：理智、客观、公正、认为原则比圆通更重要</div>
                            </a-radio>

                            <a-radio value="F" size="large">
                                <div class="text-pretty"><a-tag class="text-blue-500 font-bold text-lg">F</a-tag> - 以自己和他人感受为重，将和和谐性作为标准。例如：有同情心、善解人意，考虑行为对他人的影响</div>
                            </a-radio>
                        </a-radio-group>
                    </a-form-item>

                    <a-divider direction="horizontal" content-position="left"></a-divider>

                    <a-form-item label="4. 组织维度-我更倾向于" size="default" class="text-wrap" name="mbtiReaction">
                        <a-radio-group v-model:value="mbtiForm.mbtiReaction" class="ml-1 space-y-3">
                            <a-radio value="J" size="large">
                                <div class="text-pretty"><a-tag class="text-blue-500 font-bold text-lg">J</a-tag> - 喜欢做计划和决定，进行管理，希望生活井然有序 ，重视结果，按部就班、有条理、尊重时间期限</div>
                            </a-radio>

                            <a-radio value="P" size="large">
                                <div class="text-pretty"><a-tag class="text-blue-500 font-bold text-lg">P</a-tag> - 灵活适应环境、留有余地，喜欢宽松自由的生活方式 重视随信息的变化不断调整</div>
                            </a-radio>
                        </a-radio-group>
                    </a-form-item>
                </a-form>
            </a-card>
            <a-button type="primary" class="float-end mt-10 mb-10" size="default" @click="submit()">提交</a-button>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue';
import {StudentForm, StudentGaokaoScoreForm, StudentMbtiForm} from '@/models/signup'
import {searchAssociateMajor, searchBachelorMajor} from '@/api/request/resource'
import {useRequest} from 'vue-request'
import type { FormInstance } from 'ant-design-vue';
import { isFromWechatClient } from '@/helpers/common';
// import { OFFICIAL_ACCOUNT_PAGE_URL } from '../helpers/constants';
import {searchUniversity, updateStudentProfile} from "@/api/request/student.ts";
import { Rule } from 'ant-design-vue/es/form';
import {useProfileStore} from "@/stores/profile.ts";
import DatePicker from "@components/common_components/DatePicker.vue";

const profStore = useProfileStore()
const steps = ref([
    {
        title: "测评说明"
    },
    {
        title: "基本信息"
    },
    {
        title: "高考信息"
    },
    {
        title: "测评"
    }

])
// Step 1, 基本信息
const additionalForm = ref<StudentForm>({
    firstname: "",
    lastname: "",
    sex: "",
    university: "",
    department: "",
    major: "",
    majorType: "",
    entryDate: ""
})

// watch(entryDate, (value) => {
//     additionalForm.value.entryDate = value?.format("YYYY-MM-DD") ?? ""
// })


const additionalRules = ref<Record<string, Rule[]>>({
    lastname: [
        {
            required: true
        }
    ],
    firstname: [
        {
            required: true
        }
    ],
    university: [
        {
            required: true
        }
    ],
    majorType: [{required: true}],
    entryDate: [{required: true, pattern: /\d{4}-\d{2}-\d{2}/, trigger: 'blur'}],
    degreeYears: [{required: true}],
    department: [{required: true}],
    major: [
        {required: true}
    ],
    sex: [{required: true}]
})

const additionalFormRef = ref<FormInstance>()
function additionalFormNext() {
    additionalFormRef.value?.validateFields().then((_) => {
        next()
    })
}

watch(() => additionalForm.value.majorType, (value) => {
    if (value == 'ASSOCIATE') {
        additionalForm.value.degreeYears = 3
    }
    if (value == 'BACHELOR') {
        additionalForm.value.degreeYears = 4
    }
})

const {data: assoMajors, run: searchAssociateMajors} = useRequest(searchAssociateMajor, {
    manual: true,
    // onSuccess(data) {
    //     // console.log(data)
    //     console.log(assoMajors)
    // },
    debounceInterval: 300,
})

const {data: bachelorMajors, run: searchBachelorMajors} = useRequest(searchBachelorMajor, {
    manual: true,
    // onSuccess(data) {
    //     // console.log(data)
    //     console.log(assoMajors)
    // },
    debounceInterval: 300,
})

const {data: university, run: runSearchUniversity} = useRequest(searchUniversity, {
    manual: true,
    debounceInterval: 300,
})

// Step 2, 说明

// Step 3，高考分数
const gaokaoFormRef = ref<FormInstance>()
function gaokaoFormNext() {
    gaokaoFormRef.value?.validateFields().then((_) => {
        next()
    })
}
const gaokaoForm = ref<StudentGaokaoScoreForm>({

})

const checkScore = async (_rule: Rule, value?: number) => {
    console.log(value)
    if (typeof value == 'undefined' || value == null){
        return Promise.resolve();
    }
    if (!Number.isInteger(value)) {
        return Promise.reject('请输入正整数');
    } else {
        if (value <= 0) {
            return Promise.reject('请输入正整数');
        } else {
            return Promise.resolve();
        }
    }
};

const gaokaoRules = {
    // 分数需要为数字
    totalScore: [
        {
            // type: "number",
            // message: "请填写数字",
            trigger: "blur",
            validator: checkScore,
        },
    ],
    chinese: [
        {
            trigger: "blur",
            validator: checkScore,
        },
    ],
    mathematics: [
        {
            trigger: "blur",
            validator: checkScore,
        },
    ],
    foreignLanguage: [
        {
            trigger: "blur",
            validator: checkScore,
        },
    ],
    physics: [
        {
            validator: checkScore,
            trigger: "blur",
        },
    ],
    chemistry: [
        {
            trigger: "blur",
            validator: checkScore,
        },
    ],
    biology: [
        {
            trigger: "blur",
            validator: checkScore,
        },
    ],
    politics: [
        {
            trigger: "blur",
            validator: checkScore,
        },
    ],
    history: [
        {
            trigger: "blur",
            validator: checkScore,
        },
    ],
    geography: [
        {
            trigger: "blur",
            validator: checkScore,
        },
    ],

}

// Step 3，测评
const mbtiForm = ref<StudentMbtiForm>({
    mbtiEnergy: "",
    mbtiMind: "",
    mbtiDecision: "",
    mbtiReaction: ""
})

const mbtiRules = ref<Record<string, Rule>>({
    mbtiDecision: {
        required: true
    },
    mbtiEnergy: {
        required: true
    },
    mbtiMind: {
        required: true
    },
    mbtiReaction: {
        required: true
    }
})
// const surveyJson = {
//   elements: [{
//     name: "FirstName",
//     title: "Enter your first name:",
//     type: "text"
//   }, {
//     name: "LastName",
//     title: "Enter your last name:",
//     type: "text"
//   }]
// };

const active = ref(0)

const next = () => {
  if (active.value++ > 2) active.value = 0
}

const mbtiFormRef = ref<FormInstance>()
function submit() {
    mbtiFormRef.value?.validateFields()
    .then(() => {
        updateStudentProfile(additionalForm.value, mbtiForm.value, gaokaoForm.value)
            .then((_) => {
                if (typeof alert("提交成功！后续可以按照代理指引，通过公众号享受服务。") == "undefined") {
                    if (isFromWechatClient()) {
                        window.location.replace(profStore.orgMetadata?.redirecturl as string)
                    } else {
                        window.close()
                    }
                }

            })
    })


}


</script>

<style scoped>
.el-main {
    padding: 0;
}

.el-radio {
    white-space: inherit !important;
}
.el-radio.el-radio--large {
    height: auto !important;
}
</style>
