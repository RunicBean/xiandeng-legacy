<template>
    <div class="h-full report">
        <div class="opening flex flex-col items-center justify-evenly h-full">
            <img v-if="profileStore.orgMetadata?.uri" class="w-1/2" :src="profileStore.orgMetadata.logourl" alt="">
            <img v-else class="w-1/2" src="/images/xiandeng-report-logo.png" alt="">
            <div class="text-4xl font-bold">大学规划报告</div>
            <img class="w-4/5" src="/images/meihaoweilai.png" alt="">
        </div>

        <a-anchor class="text-lg" :offset="70" direction="horizontal" :items="anchorItems" />
        <h3 id="basic-info">一、个人信息</h3>

        <table class="m-auto" border="1" cellpadding="10">
            <tr>
                <td>姓名：{{ name }}</td>
                <td>性别：{{ formatSex(reportData?.sex) }}</td>
            </tr>
            <tr>
                <td>院校：{{ reportData?.university }}</td>
                <td>专业：{{ reportData?.major }}</td>
            </tr>
        </table>

        <h3 id="gaokao">二、高考信息</h3>

        <table class="m-auto" border="1" cellpadding="10">
            <thead>
                <tr>
                    <th>总分</th>
                    <th>语文</th>
                    <th>数学</th>
                    <th>外语</th>
                    <th>物理</th>
                    <th>化学</th>
                    <th>生物</th>
                    <th>政治</th>
                    <th>历史</th>
                    <th>地理</th>
                </tr>
            </thead>
            <tbody>
            <tr>
                <td class="text-center">{{reportData?.total_score}}</td>
                <td class="text-center">{{reportData?.chinese ? reportData?.chinese : '-'}}</td>
                <td class="text-center">{{reportData?.mathematics ? reportData?.mathematics : '-'}}</td>
                <td class="text-center">{{reportData?.foreign_language ? reportData?.foreign_language : '-'}}</td>
                <td class="text-center">{{reportData?.physics ? reportData?.physics : '-'}}</td>
                <td class="text-center">{{reportData?.chemistry ? reportData?.chemistry : '-'}}</td>
                <td class="text-center">{{reportData?.biology ? reportData?.biology : '-'}}</td>
                <td class="text-center">{{reportData?.politics ? reportData?.politics : '-'}}</td>
                <td class="text-center">{{reportData?.history ? reportData?.history : '-'}}</td>
                <td class="text-center">{{reportData?.geography ? reportData?.geography : '-'}}</td>
            </tr>
            </tbody>

        </table>

        <h3 id="studyingsuggestion">三、专业规划</h3>
        <p v-if="isAssociate">{{ reportData?.studyingsuggestion }}</p>


        <h3 id="develop-options" v-if="isAssociate">四、可选发展路径</h3>
        <p>根据你的院校及专业情况，你的未来发展有很多方向。这里从<b class="text-xl">升学</b>和<b class="text-xl">就业</b>两大维度来为你介绍其中比较优渥的发展路径：</p>

        <h4 id="studing">（一）升学</h4>
        <template v-if="isBachelor">
            <template v-if="isGraduateEligible">
                <h5 id="baoyan">A：保研</h5>
                <p>保研的优势在于通过读研，提升学历水平（提升院校履历及学位证）。读研期间与导师建立深厚链接，获取更高层级的人脉资源，甚至通过导师资源直接获得稀缺就业机会。</p>

                <div class="custom-image">
                    <a-image :src="imgSource[0]" fit="fill"></a-image>
                </div>
            </template>


            <h5 id="kaoyan"><span v-if="isGraduateEligible">B：</span><span v-else>&nbsp;&nbsp;&nbsp;</span>考研</h5>
            <p>对于失去保研资格的同学，依然可以通过全国统一研究生入学考试获得读研机会。考研的优势除提升学历水平（提升院校履历及学位证），获取更高层人脉资源外，亦可以通过跨专业报考，改换专业。</p>
            <div class="custom-image">
                <a-image :src="imgSource[1]" fit="fill"></a-image>
            </div>
        </template>
        <template v-if="isAssociate">
            <h5 id="zhuanshengben">专升本:</h5>
            <p>专升本不仅能实现学历跃升，更对职业发展、个人成长产生深远影响。不仅可以获得全日制本科学历，更能突破大部分企业的求职门槛，获得更宽的职业选择道路，以及更高的起始薪资和更多的晋升机会。再未来个人能力深造与资源拓展方面也可解锁更多可能性。诸如考研，考博，各类职业资格证报考等等。</p>
            <p>专升本是以省为单位组织招考，因此各个不同省份招考形式政策皆有不同。其中辽宁省专升本因其考试科目相对简单，专业选择限制少，报考次数不限等特点，故而优先推荐报考辽宁省专升本。</p>

            <table class="m-auto border border-gray-400 mt-10 mb-10" cellpadding="10">
                <thead>
                    <tr>
                        <th>辽宁省专升本考试科目</th>
                        <th>分值</th>
                        <th>命题单位</th>
                    </tr>
                </thead>
                <tbody>
                <tr>
                    <td>《计算机应用基础》</td>
                    <td>100分</td>
                    <td rowspan="3">辽宁省招生考试委员会<br>
                        全省统一命题考试</td>
                </tr>
                <tr>
                    <td>《英语》《日语》《俄语》（任选其一）</td>
                    <td>120分</td>
                </tr>
                <tr>
                    <td>《数学》或《思想道德修养与法律基础》</td>
                    <td>120分</td>
                </tr>
                <tr>
                    <td>《专业综合课》</td>
                    <td>300分</td>
                    <td rowspan="2">由辽宁省教育厅指定的省级<br>“牵头院校”负责命题</td>
                </tr>
                <tr>
                    <td>《专业技能测试》</td>
                    <td>100分</td>
                </tr>
                </tbody>
            </table>

            <p>以下是专升本备考的系统化时间轴规划，分阶段明确任务重点，帮助你从大一到大三科学备战：</p>
            <p class="font-bold">大一阶段：基础准备与方向定位（提前1.5-2年）</p>
            <p><strong>核心任务：</strong>信息收集+基础巩固+习惯养成</p>
            <p class="font-bold">学习重点：</p>
            <p>英语：每日背30个高频词汇，每周精读1篇四级难度文章</p>
            <p>数学（若需考）：复习高中函数、数列基础，完成教材课后习题</p>
            <p>专业课：通读专业基础教材（如管理学/教育学），标注核心概念</p>
            <p class="font-bold">大二阶段：系统复习与强化训练（考前10-12个月）</p>
            <p><strong>核心任务：</strong>知识框架构建+弱项突破</p>
            <p class="font-bold">分阶段规划：</p>
            <p class="font-bold">1. 基础夯实期（3月-6月）</p>
            <p>英语：语法专项训练（重点：从句/时态），词汇量突破3500词</p>
            <p>专业课：整理章节思维导图，完成第一轮知识点扫盲（配套练习正确率≥60%）</p>
            <p>公共课：政治理论通读教材，标记时政热点章节</p>
            <p class="font-bold">2. 暑假黄金期（7月-8月）</p>
            <p>每日6-8小时，重点抓上午9-11点、下午3-5点高效时段</p>
            <p>英语：分模块训练（完形/阅读/写作），精析近5年真题</p>
            <p>专业课：建立“考点-真题”对应表，整理背诵清单（如教育学的人物理论+案例）</p>
            <p>数学/政治：完成专题训练（数学注重计算规范，政治梳理历史事件年表）</p>
            <p class="font-bold">大三阶段：冲刺与实战（考前3-6个月）</p>
            <p class="font-bold">1. 冲刺攻坚期（9月-12月）</p>
            <p><strong>核心任务：</strong>真题模拟+政策跟进</p>
            <p>每周2套限时真题模考（严格按考试时间）</p>
            <p>建立错题TOP10清单（重点分析错误根源</p>
            <p class="font-bold">2. 考前决胜期（次年1月-考试日）</p>
            <p>1月-2月：英语作文模板优化（准备3套不同类型），专业课高频考点循环背诵</p>
            <p>考前30天：停止刷新题，专注错本本+公式/概念回顾</p>
            <p>考前1周：调整生物钟匹配考试时间，准备考试物品</p>
        </template>

        <h4 id="job-retrieving">（二）就业</h4>
        <div class="custom-image">
            <a-image :src="imgSource[2]" fit="fill"></a-image>
        </div>

        <h5 id="yangguoqi">A：央国企</h5>
        <p>大型央国企基本只招聘应届生，且基本不做校园招聘，因此在学生中存在信息差，了解央国企招聘信息和渠道的人占比极低。成功入职央国企，可获得体制内编制身份。收入较高且稳定，无后顾之忧，福利众多，法定假日不缺席，平日工作不加班，生活幸福感获得感高，社会地位受人尊敬。另外，央国企的发展路径可深造为专家型岗位或管理型岗位（走从政路线）。你所学专业，可报考的目标央国企包括：国家电网，中国移动，中国石化，中国航空航天，中国兵器，保利集团，国家开发投资集团等242家涉及制造，金融，民生等不同产业领域的央企。</p>

        <h5 id="buduiwenzhi" v-if="isBachelor">B：部队文职</h5>
        <p>部队各单位每年会招聘应届毕业生充入军队文职岗位，从事技术支持或行政后勤工作。待遇非常优厚，获得正式部队编制，可长期深耕走军队系统发展路线，职业身份高，无后顾之忧。部队文职不做校园招聘，因此在学生中存在信息差，了解相应招聘信息和渠道的人占比极低。可报考单位包括：国防大学，火箭军，武警部队，军委后勤保障部，军委科学技术委员会，战略支援部队等等众多单位。</p>

        <h5 id="xuandiaosheng" v-if="isBachelor">C：选调生</h5>
        <p>选调生是党中央及各省党委组织部门有计划地从高等院校选调品学兼优的应届大学本科及其以上毕业生到基层工作，作为党政领导干部后备人选和县级以上党政机关高素质的工作人员人选进行重点培养的人才招聘渠道。</p>
        <p>作为预备干部，选调生职业起点远高于普通公务员，晋升发展也最快，是从政路线最优发展方向。</p>

        <h5 id="sanzhiyifu" v-if="isBachelor">D：三支一扶</h5>
        <h5 id="sanzhiyifu" v-if="isAssociate">B：三支一扶</h5>
        <p>三支一扶为支教，支医，支农。通过各省统一考试可获得录取名额。参加为期2年的基层服务工作。2年后，考核合格有机会直接获得入编机会。个别地区暂无入编机会的，亦可以被视同具有2年基层工作经验的人员，享受公务员和事业单位定向考录招聘的优惠政策。若继续升学，无论保研还是考研，则可以获得相应的政策优惠。</p>

        <h5 id="kaogong" v-if="isBachelor">E：考公</h5>
        <h5 id="kaogong" v-if="isAssociate">C：考公</h5>
        <p>公务员考试分为国考和省考，分别对应中央、国家机关公务员录用考试，和各省市地区政府公务员录用考试。考试每年一次，35岁以下皆可报考。公务员收入稳定，职业地位较高，社会资源深厚，亦可长远发展走从政路线。</p>

        <h3 id="mywords">五、送给你一段掏心窝的话</h3>
        <p>大学是一个精心布置的<span class="kw">迷宫</span>，并不存在一条主路或标准走法。每一条小路，例如科研、学生会、实习等都各有乾坤。学生们在各条小路之中穿行探索，一边选择路线，一边在路途上收集着有价值的<span class="kw">筹码</span>，包括成绩、经历、奖项等等。</p>
        <p>迷宫的出口有很多，升学，求职，出国留学等等。不同的出口对应着不同的筹码要求。而最优质的出口，往往只在快走完整个迷宫时才会猛然被大家发现，而那个时候，<span class="kw">90%</span>的学生们手里的筹码是不足以支付这些最优质出口的。只有那些有着雄厚家庭<span class="kw">背景</span>或者独家<span class="kw">资源</span>的孩子，才会在进入迷宫中之前就拿到一份完整的迷宫<span class="kw">攻略</span>甚至是清晰的<span class="kw">地图</span>，去有的放矢地高效收集筹码，这就是我们常说的<span class="kw">信息差</span>和<span class="kw">资源差</span>。</p>
        <p>多年的高等教育从业经验及一线央国企/百强企业招聘经验，让我们在帮助大学生就业方面有着独家的稀缺资源，<span class="text-xl font-bold">先登社区</span>是专为在校大学生学业规划及个人发展的私域社区，旨在帮助社区里的家长和孩子 <span class="kw">消弭信息差和资源差</span>，通过持续4年的<span class="kw">全方位管家式陪伴服务</span>，让平民子弟也可以获得“<span class="kw">小圈子里的内部资源</span>”，走出一条更宽广的人生坦途。</p>
        <p>因此，当你正准备迈入大学生涯却疑惑大学该做哪些有用的事，当你正处在迷宫的分岔口（保研/考研/央国企/部队文职/选调生/其他就业等等）时，当你看到有用的筹码（论文发表/专利申请/高质量实习等等）想拿取却摸不到门路时，请及时联系我们。不错过人生中每一个机会点，就能积累出美好的未来！</p>

        <h3 id="mbtisuggestion">附赠：学习风格建议（全国独家）</h3>
        <div class="custom-image">
            <a-image :src="imgSource[3]" fit="fill"></a-image>
        </div>
        <p>{{ reportData?.charactersuggestion }}</p>
    </div>
</template>

<script setup lang="ts">
import {formatSex} from '@/models/account'
import type {PlanningReportData} from "@/api/request/service.ts";
import {computed} from "vue";
import {useProfileStore} from "@/stores/profile.ts";

const profileStore = useProfileStore()

const props = defineProps<{
    reportData?: PlanningReportData,
    isGraduateEligible: boolean
}>()

// 区分ASSOCIATE / BACHELOR
const isAssociate = computed(() => {
    if (!props.reportData) {return false}
    else {
        return props.reportData.degree === "ASSOCIATE"
    }
})

const isBachelor = computed(() => {
    if (!props.reportData) {return false}
    else {
        return props.reportData.degree === "BACHELOR"
    }
})

// 就读建议分流
// const bachelorStudySuggestion = computed(() => {
//     if (!props.reportData) {return ""}
//     const paraphs = props.reportData.genstudysuggestion.split("\n\n")
//     const newParaphs = paraphs.slice(0, 2)
//     newParaphs.push(props.reportData.core_course_learning)
//     newParaphs.push(props.reportData.practical_skill_development)
//     newParaphs.push(props.reportData.skill_expansion)
//     newParaphs.push(paraphs[2])
//     return newParaphs.join("\n\n")
// })

const name = computed(() => {
    if (!props.reportData) {return ""}
    else if (!props.reportData.lastname || !props.reportData.firstname) {
        return ""
    } else {
        return props.reportData.lastname + props.reportData.firstname
    }

})

const anchorItems = [
  {
    key: 'basic-info',
    href: '#basic-info',
    title: '1 个人信息',
  },
    {
        key: 'gaokao',
        href: '#gaokao',
        title: '2 高考信息',
    },
  {
    key: 'studyingsuggestion',
    href: '#studyingsuggestion',
    title: '3 专业规划',
  },
  {
    key: 'majorreference',
    href: '#majorreference',
    title: '4 升学规划',
  },
  {
    key: 'develop-options',
    href: '#develop-options',
    title: '5 学术',
  },
  {
    key: 'mywords',
    href: '#mywords',
    title: '6 综合事项',
  },
  {
    key: 'mbtisuggestion',
    href: '#mbtisuggestion',
    title: '7 就业',
  },

]

const imgSource = [
    "/images/planning-report/baoyan1.png",
    "/images/planning-report/kaoyan1.png",
    "/images/planning-report/job1.png",
    "/images/planning-report/mbti.png",
]
</script>

<style scoped>
/* table, td {
    border: 1px solid;
} */
td {
    background-color: #c9ecff;
}
table {
    border-collapse: separate;
    width: 70%;
}

.report > p {
    width: 70%;
    margin: auto;
    white-space: pre-line;
    line-height: 2rem;
    text-indent: 2rem;


}

.report >p >b {
        color: #2d7aa4;
    }

.report > .custom-image {
    width: 80%;
    margin: auto;
}

.report > h3 {
    margin-top: 2rem;
    width: 80%;
    margin-inline: auto;
}

.report > h4,h5 {
    margin-top: 1rem;
    width: 75%;
    margin-inline: auto;
}

span.kw {
    color: red;
    font-weight: 600;
}
</style>
