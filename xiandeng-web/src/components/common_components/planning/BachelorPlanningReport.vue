<template>
    <div class="h-full report">
<!--        <div class="opening flex flex-col items-center justify-evenly h-full">-->
<!--            <img v-if="profileStore.orgMetadata?.uri" class="w-1/2" :src="profileStore.orgMetadata.logourl" alt="">-->
<!--            <img v-else class="w-1/2" src="/images/xiandeng-report-logo.png" alt="">-->
<!--            <div class="text-4xl font-bold">大学规划报告</div>-->
<!--            <img class="w-4/5" src="/images/meihaoweilai.png" alt="">-->
<!--        </div>-->
        <div id="cover-page" class="w-[90vw] my-10 lg:my-0 lg:w-[210mm]">
            <img class="h-[25vw] max-h-60" src="/images/planning-report/xiandeng-logo-outline.png" alt="">
            <div class="text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-black ms-[10%] mt-[10%]">大学规划报告</div>
            <div class="md:text-lg text-start ms-[20%] mt-[20%] space-y-2">
                <div>姓名：{{ name }}</div>
                <div>院校：{{ reportData?.university }}</div>
                <div>专业：{{ reportData?.major }}</div>
            </div>
        </div>
<!--        <img src="/images/planning-report/xiandeng-planning-bg.png" alt="">-->

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
<!--            <tr>-->
<!--                <td>入学年月：{{ reportData?.entry_date ? dayjs(reportData?.entry_date).format('YYYY-MM') : "-" }}</td>-->
<!--            </tr>-->
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
        <div class="flex flex-col items-center gap-y-3 my-10">
            <img class="w-[20vw]" :src="reportData?.universitylogo" alt="">
            <div class="text-lg font-semibold">{{reportData?.university}}</div>
        </div>
        <bachelorStudySuggestion />
        <br>
        <p class="no-ind">若对本专业不满意，想要该换赛道，可以考虑转专业或通过辅修/第二学位，甚至考研等方式学习新的专业：</p>
        <h5>转专业</h5>
        <p class="font-bold no-ind">时间：每学年第二学期第4周前</p>
        <p class="font-bold no-ind">条件：</p>
        <ol>
            <li>在校全日制学习的本科一、二年级学生提前录取专业学生、国防生等属特殊类型招生的学生不得转专业 </li>
            <li>确有专长，更适合在其它专业学习，或者因身体及其它原因（隐瞒既往病史入学者除外、不能适应现专业学习因身体原因需要转专业者，需要提交校医院或者学校指定医院的诊断证明</li>
            <li>已修公共课的成绩应在“B”以上，专业课成绩在“C”以上</li>
            <li>在校期间未受过任何纪律处分</li>
        </ol>
        <p class="no-ind text-red-500 font-semibold">具体规划及操作方法可学习《大学生涯规划一本通》专题四：《高校转专业通知来了，孩子要不要转专业？》，先登社区内也提供专业方向选择的1V1咨询指导</p>
        <h5>辅修/第二学位</h5>
        <ol>
            <li><b>辅修学士学位：</b><br>
                大多高校都可以辅修学士学位，但需要注意的是，市场对辅修的认知度不同，有些行业对辅修的专业认同等同于第一学位，有些则不然，所以在辅修前要多了解。
            </li>
            <li><b>修第二学位:</b> <br>
                <p>与辅修不同，第二学位需在本科四年毕业后再学两年，才能拿到第二学位，而且需要考试。修第二学位是全日制脱产学习，但学生可以申请在其他学校就读。
                </p>
                <p>2020 年 5 月 29 日，教育部高等教育司官网发布了《在普通高校继续开展第二学士学位教育的通知》。
                </p>
                <p>7 月 10 日，教育部网站公布了 2020 年普通高等学校第二学士学位专业备案的结果，共有497 所高校，累计开设了 3426 个第二学士学位专业，学制均为两年。
                </p>
            </li>
        </ol>
        <p class="no-ind text-red-500 font-semibold">具体规划及操作方法可学习《大学生涯规划一本通》专题五：《辅修学士学位详细介绍及最全申请攻略》，先登社区内也提供辅修双修等1V1咨询指导</p>


        <h3 id="majorreference">四、升学规划</h3>
        <template v-if="reportData?.isgraduateeligible">
            <h5 id="baoyan">保研</h5>
            <p>（一）保研概述</p>
            <p>保研的优势在于通过读研，提升学历水平（提升院校履历及学位证）。读研期间与导师建立深厚链接，获取更高层级的人脉资源，甚至通过导师资源直接获得稀缺就业机会。保研推免生评定标准主要包括成绩、科研能力、综合素质和推荐信。考试内容通常为专业课笔试和面试，重点考察专业知识和科研潜力。准备时应注重专业知识复习、科研项目积累和面试技巧提升。</p>
            <p>（二）保研规划时间轴 </p>
            <table class="mx-auto text-center baoyan-schedule-table">
                <thead>
                <tr>
                    <th>阶段</th>
                    <th>时间节点</th>
                    <th>核心任务</th>
                    <th>成败关键</th>
                </tr>
                </thead>
                <tbody>
                <tr>
                    <td>早期准备</td>
                    <td>大一至大三上</td>
                    <td>成绩/英语/科研竞赛</td>
                    <td>排名靠前+硬核加分项</td>
                </tr>
                <tr>
                    <td>材料投递</td>
                    <td>大三下3-6月</td>
                    <td>文书打磨+夏令营海投</td>
                    <td>精准定位+材料专业性</td>
                </tr>
                <tr>
                    <td>夏令营</td>
                    <td>大三暑假7-8月</td>
                    <td>笔试面试+争取优营</td>
                    <td>专业课深度+英语应变力</td>
                </tr>
                <tr>
                    <td>预推免</td>
                    <td>大四8-9月上旬</td>
                    <td>二次投递+本校资格确认</td>
                    <td>信息搜集+快速响应</td>
                </tr>
                <tr>
                    <td>系统录取</td>
                    <td>大四9.28-10月</td>
                    <td>志愿填报+确认录取</td>
                    <td>策略选择（冲/保）+时效性</td>
                </tr>
                </tbody>
            </table>
            <p class="no-ind text-red-500 font-semibold">具体规划及操作方法可学习《大学生涯规划一本通》专题八：《最全保研流程及详细攻略》，先登社区内也提供保研训练营等指导</p>

        </template>

        <h5 id="kaoyan">考研：</h5>
        <p class="font-semibold">（一）考研概述</p>
        <p>对于没有/失去保研资格的同学，依然可以通过全国统一研究生入学考试获得读研机会。考研的优势除提升学历水平（提升院校履历及学位证），获取更高层人脉资源外，亦可以通过跨专业报考，改换专业。各学院自主招生，名额有限，分数要求：国家线为基础，部分热门专业需超国家线。考试内容： 政治、英语、数学、专业课，或者个别专业考察管理类综合。</p>
        <p class="font-semibold">（二）考研规划</p>
        <p>1. 考研是典型的选拔性考试，因此考试难度非常大，竞逐环境非常激烈。全国报录比维持在4：1左右。因此想要考研的同学，要提前做好艰苦学习的心理准备，也提前做好考研落榜的心里铺垫。
        </p>
        <p>2. 考研初试时间在大四上学期12月份，一般考研学习准备周期是初试前一年，大三上学期开始准备考研的备考学习，跨专业同学建议较早启动。根据考研报考专业不同，考研科目也有所不同。具体各个科目如下：</p>
        <p><span class="font-semibold">【政治】：</span>国家统考</p>
        <p>分值：100分</p>
        <p>内容：《马克思主义基本原理》、《毛泽东思想和中国特色社会主义理论体系概论》、《习近平新时代中国特色社会主义思想概论》、《中国近代史纲要》、《思想道德与法制》；</p>

        <p><span class="font-semibold">【外国语】：</span>（以英语为主）</p>
        <p>分值：100分</p>
        <p>内容：重点考察学术论文的阅读能力，根据难度不同，分为英语一和英语二两个梯度。</p>

        <p><span class="font-semibold">【数学】：</span>国家统考</p>
        <p>分值：100分</p>
        <p>内容：根据难度不同，分为三个梯度。具体由选报的专业来决定。</p>
        <p>数学一：理工科（如计算机、电子工程），含高等数学（56%）、线性代数（22%）、概率论（22%）。</p>
        <p>数学二：工科（如轻工、生物工程），仅考高等数学（78%）和线性代数（22%）。</p>
        <p>数学三：经管类（如经济学、管理学），含高等数学（56%）、线性代数（22%）、概率论（22%），难度降低但侧重经济应用。</p>
        <p>*替代科目：部分专业不考数学，改为专业基础课（如化学、生物学等） </p>

        <p><span class="font-semibold">【专业课】：</span>根据报考目标专业不同，专业课内容也有所不同</p>
        <p>1.	专业基础综合（部分学科统考）</p>
        <p>分值：150分或300分</p>
        <p>适用专业：300分综合科目：教育学（311/333）、心理学、历史学、医学（西医/中医综合）等。150分专业基础：如计算机（数据结构、操作系统）、法学（专业基础课）</p>
        <p>2.	专业核心课（院校自命题）</p>
        <p>分值：150分</p>
        <p>内容：与报考专业直接相关的核心知识。例如：文学考文学史，医学考病理学/解剖学，建筑学考6小时快题设计</p>

        <p><span class="font-semibold">【管理类联考】（199科目）：</span>部分特殊专业考察该科目。</p>
        <p>适用专业：MBA、会计、图书情报等专硕。</p>
        <p>内容：逻辑推理、数学（初等）、写作，满分200分。</p>

        <p class="no-ind text-red-500 font-semibold">先登社区内提供全部考研国家统考科目的课程及题库等学习资源</p>


        <h3 id="develop-options">五、学术积累</h3>
        <h4>一、奖学金</h4>
        <p>奖学金是直接证明个人学习成绩的方式。获得奖学金的次数及奖学金级别，直接反映个人的学习态度，学术基础。</p>
        <p>本科奖学金种类非常丰富，金额也很丰厚，包括如下类型:</p>
        <p>1.	国家奖学金是指国家为了激励普通本科高校、高等职业学校和高等专科学校学生勤奋学习、努力进取，由中央政府出资设立的奖励特别优秀学生的奖学金。从2024年起，将本专科生国家奖学金奖励名额由每年6万名增加到12万名，奖励标准由每生每年8000元提高到10000元。 </p>
        <p>2.	国家励志奖学金是为了激励普通本科高校、高等专科学校的家庭经济困难学生勤奋学习、努力进取，在德、智、体、美等方面全面发展，由中央和地方政府共同出资设立的，奖励资助品学兼优的家庭经济困难学生的奖学金。从2024年起，将本专科生国家励志奖学金奖励标准由每生每年5000元提高到6000元。与国家奖学金不同，国家励志奖学金针对家庭贫困的学生，需要先提供相关证明，成为贫困生。</p>
        <p>3.	专业奖学金主要由学校设立，是综合考察学生的成绩、思想品质、文体特长等素质的奖学金，由学校设置，大致分为一二三等。每个学校之间有比较大的区别，比如，清华大学的学业单项奖学金，一等奖3000元，二等奖2000元，三等奖1000元，人民大学的学习优秀奖学金，特等奖3000元，一等奖1200元，二等奖800元，三等奖600元。</p>
        <p>4.	其他奖学金:校内单项奖学金、校友奖学金、企业赞助奖学金等。只要认真学习不仅能拿到奖学金，对考研、保研也有很大帮助，可谓名利双收!</p>

        <p class="no-ind text-red-500 font-semibold">具体规划及操作方法可学习《大学生涯规划一本通》专题三：《大学奖学金怎么拿》</p>

        <h4>二、	专业竞赛：</h4>
        <h5>（一）理工科类竞赛</h5>
        <p>理工科竞赛侧重专业知识应用、技术研发、问题解决能力，多涉及实验、建模、编程、工程设计等。</p>
        <p class="no-ind font-semibold">1. “挑战杯” 全国大学生课外学术科技作品竞赛</p>
        <ul class="list-disc ps-8">
            <li>主办方：共青团中央、教育部、中国科协等</li>
            <li>特点：综合性强，涵盖自然科学类学术论文、科技发明制作、社会科学类社会调查报告等，被誉为 “中国大学生科技创新的奥林匹克盛会”。</li>
            <li>面向专业：理工科为主，兼顾跨学科项目。</li>
        </ul>
        <p class="no-ind font-semibold">2. 全国大学生数学建模竞赛（CUMCM）</p>
        <ul class="list-disc ps-8">
            <li>主办方：教育部高等教育司、中国工业与应用数学学会</li>
            <li>特点：3 人团队在 3 天内解决一个实际问题（如环境、经济、工程等领域），提交数学建模论文，强调逻辑建模与软件应用（如 MATLAB、Python）。</li>
            <li>延伸：国际赛事有美国大学生数学建模竞赛（MCM/ICM），影响力更广泛。</li>
        </ul>
        <p class="no-ind font-semibold">3. 全国大学生电子设计竞赛</p>
        <ul class="list-disc ps-8">
            <li>主办方：教育部高等教育司、信息产业部人事司</li>
            <li>特点：4 人团队在 4 天内完成电子电路设计、制作与调试（如智能车、通信系统、测量仪器等），侧重硬件与软件结合，考验工程实践能力。</li>
        </ul>
        <p class="no-ind font-semibold">4. ACM 国际大学生程序设计竞赛（ACM-ICPC）</p>
        <ul class="list-disc ps-8">
            <li>主办方：ACM（国际计算机学会）</li>
            <li>特点：3 人团队在 5 小时内解决 8-10 道算法编程题，编程语言不限（C/C++、Python 等），侧重算法设计与代码实现，是计算机专业最具影响力的竞赛之一。</li>
        </ul>
        <p class="no-ind font-semibold">5. 全国大学生机器人大赛</p>
        <ul class="list-disc ps-8">
            <li>主办方：教育部高等学校自动化类专业教学指导委员会等</li>
            <li>特点：团队设计、制作机器人完成特定任务（如格斗、搬运、竞技），涵盖机械设计、控制系统、人工智能等多学科知识。</li>
        </ul>

        <h5>（二）文科类竞赛</h5>
        <p>文科竞赛侧重语言应用、逻辑思辨、人文素养与社会洞察，多涉及写作、辩论、调研、语言能力等。</p>
        <p class="no-ind font-semibold">1. 全国大学生英语竞赛（NECCS）</p>
        <ul class="list-disc ps-8">
            <li>主办方：国际英语外语教师协会中国英语外语教师协会、高等学校大学外语教学研究会</li>
            <li>特点：分 A（研究生）、B（英语专业）、C（非英语专业本科）、D（专科）类，题型包括听力、阅读、写作、智力测试，侧重英语综合应用能力。</li>
        </ul>

        <p class="no-ind font-semibold">2. “外研社・国才杯” 全国大学生英语挑战赛</p>
        <ul class="list-disc ps-8">
            <li>主办方：外语教学与研究出版社</li>
            <li>特点：分演讲、写作、阅读、辩论等子赛事，强调英语表达与批判性思维，决赛多为现场对抗或展示。</li>
        </ul>
        <p class="no-ind font-semibold">3. 全国大学生文学作品大赛</p>
        <ul class="list-disc ps-8">
            <li>主办方：中国散文学会、全国大学生文学作品大赛组委会</li>
            <li>面向专业：中文、新闻、文秘等文科专业及文学爱好者</li>
            <li>特点：涵盖小说、散文、诗歌、评论等体裁，侧重文学创作能力与人文思考。</li>
        </ul>
        <p class="no-ind font-semibold">4. 全国大学生模拟联合国大会</p>
        <ul class="list-disc ps-8">
            <li>主办方：各高校或国际模拟联合国协会（IMUNA）合作机构</li>
            <li>特点：模拟联合国会议流程，学生扮演各国代表，围绕国际议题（如气候变化、人权）进行辩论、谈判、起草决议，考验外交思维、英语表达与跨文化沟通能力。</li>
        </ul>

        <h5>（三）商科与创新创业类竞赛</h5>
        <p>这类竞赛聚焦商业思维、创新实践、团队协作，多与市场需求、商业模式设计结合。</p>
        <p class="no-ind font-semibold">1. 中国 “互联网 +” 大学生创新创业大赛</p>
        <ul class="list-disc ps-8">
            <li>主办方：教育部等 12 部委</li>
            <li>特点：分高教主赛道、“青年红色筑梦之旅” 赛道、产业命题赛道等，涵盖科技成果转化、社会公益创业、乡村振兴等方向，强调项目的创新性、可行性与社会价值，决赛含路演答辩环节。</li>
        </ul>

        <p class="no-ind font-semibold">2.“挑战杯” 中国大学生创业计划竞赛</p>
        <ul class="list-disc ps-8">
            <li>主办方：共青团中央、教育部等</li>
            <li>特点：侧重商业计划书撰写、项目可行性分析，涵盖产品设计、市场定位、营销策略、财务规划等，分为创意组、初创组、成长组，鼓励科技与商业结合。</li>
        </ul>
        <p class="no-ind font-semibold">3. 全国大学生电子商务 “创新、创意及创业” 挑战赛（三创赛）</p>
        <ul class="list-disc ps-8">
            <li>主办方：教育部高等学校电子商务类专业教学指导委员会</li>
            <li>面向专业：电子商务、市场营销、管理等相关专业</li>
            <li>特点：围绕电子商务领域的创新模式、创意方案或创业项目展开，强调 “创新 + 创意 + 创业” 结合，需提交方案、演示视频及现场答辩。</li>
        </ul>
        <p class="no-ind font-semibold">4. 国际企业管理挑战赛（GMC）</p>
        <ul class="list-disc ps-8">
            <li>主办方：中国管理现代化研究会国际商务谈判专业委员会</li>
            <li>特点：模拟企业运营决策，团队通过计算机软件管理虚拟企业（涉及生产、营销、财务、人力资源等），根据市场变化调整策略，考验数据分析与企业管理能力。</li>
        </ul>

        <h5>（四）艺术类与设计类竞赛</h5>
        <p>侧重创意表达、美学设计、技术实现，与视觉传达、产品设计、数字媒体等专业结合。</p>
        <p class="no-ind font-semibold">1. 全国大学生广告艺术大赛（大广赛）</p>
        <ul class="list-disc ps-8">
            <li>主办方：教育部高等学校新闻传播学类专业教学指导委员会、中国高等教育学会广告教育专业委员会</li>
            <li>面向专业：广告、设计、传媒、美术等相关专业</li>
            <li>特点：围绕企业命题（如品牌推广、公益宣传）创作广告作品，形式包括平面、视频、动画、互动广告等，强调创意与市场结合。</li>
        </ul>

        <p class="no-ind font-semibold">2.全国大学生工业设计大赛</p>
        <ul class="list-disc ps-8">
            <li>主办方：教育部高等学校工业设计专业教学指导分委员会</li>
            <li>特点：聚焦产品设计（如智能设备、家居用品、医疗仪器），要求作品兼具功能性、创新性与美学价值，需提交设计草图、模型（或效果图）及设计说明。</li>
        </ul>
        <p class="no-ind font-semibold">3. 全国大学生数字媒体艺术设计大赛</p>
        <ul class="list-disc ps-8">
            <li>主办方：工业和信息化部人才交流中心</li>
            <li>特点：涵盖数字图像、交互设计、动画短片、游戏设计等方向，侧重数字技术与艺术创意的融合，适合数字媒体、视觉传达、动画等专业学生。</li>
        </ul>
        <p class="no-ind text-red-500 font-semibold">具体规划及操作方法可学习《大学生涯规划一本通》专题七：《盘点那些值得大学生参加的高含金量竞赛》。先登社区内也提供各类竞赛的咨询指导</p>

        <h4>三、	考取证书：</h4>
        <h5>英语四级</h5>
        <ol class="list-decimal">
            <li>英语四级对于学生来说是一项很重要的证书，一年可以考2次，分为6月份和12月份。有的学校大一12月份不开放四级考试，如果大一12月份可以考，一定要把握住机会!
                </li>
            <li>四级总分710分，425分通过，对于有保研、考研需求同学来说，建议四级分数不低于500分。
                </li>
            <li>四级证书在考研、保研面试以及央国企、大型企业面试中，都是很重要的参考指标。</li>
        </ol>
        <h5>计算机二级</h5>
        <ol class="list-decimal">
            <li>大一下学期就可以参加考试，二级主要考核计算机语言与基础程序设计能力，以及办公软件高级应用能力。
                </li>
            <li>计算机二级在保研、求职、考公以及部分大城市落户等方面都有一定的加分项。
            </li>
        </ol>
        <h5>其他证书</h5>
        <p>大学可考取的证书很多。除全体同学都要考的英语四六级和计算机二级之外，还有其他与专业相关的各类证书。</p>
        <p class="no-ind text-red-500 font-semibold">具体规划及操作方法可学习《大学生涯规划一本通》专题二：《大学四年考证规划》，先登社区也提供所有常见考证科目的课程及题库等学习资源</p>

        <h4>四、	论文发表：</h4>
        <p>专业论文发表是指学生就所学专业领域的某个主题进行研究，撰写学术论文，通过期刊等渠道发布。如果本科期间可以发表论文，对于学生的考研、保研面试，就业等环节都有很大的帮助。
            </p>
        <p>建议大一尝试论文的学习和研究，为大二、大三发表论文积累经验。大一发表论文相对较难，但是可以提前学习了解，尤其了解论文发表的方法和步骤。
        </p>
        <p class="no-ind text-red-500 font-semibold">具体规划及操作方法，先登社区内包含论文发表全流程课程指导及相应导师资源</p>

<!--        Overall -->
        <h3 id="overall">六、综合事项</h3>
        <h4>一、	学生干部</h4>
        <p>学生干部经历是重要的大学校园经历。无论对于同学将来保研，考研复试，以及各个求职方向，都具有非常大的加分意义。同时，学生干部身份，也有利于同学更方便更频繁地接触导员等大学重要人脉资源，获得更多甚至是独家的发展机会。</p>
        <h5>· 班委</h5>
        <ol class="list-decimal">
            <li>建议同学积极竞选，从军训期间就主动帮助老师和同学处理班级事务，更有利于团结同学，胜选概率更大!班委是大学四年都可持续做的。
                </li>
            <li>可以锻炼组织协调能力、更大几率获得入党和评奖评优机会，同时为就业简历增色。
                </li>
            <li>暑假期间准备好自我介绍、练习好上台竞选演讲!</li>
        </ol>
        <h5>· 学生会</h5>
        <ol class="list-decimal">
            <li>建议同学大一入学积极参加学生会，最好直接面试校学生会!大二之后建议退出预留更多时间做对毕业有利的事情。
                </li>
            <li>参加学生会有利于拓展人脉、锻炼社交能力、更大几率获得入党机会、评奖评优奖学金中加分，同时为就业简历增色，很多企业看重学生会工作经历，有机会获得领导推荐就业。
                </li>
            <li>暑假期间准备好自我介绍、练习好上台竞选演讲!
            </li>
        </ol>
        <p class="no-ind text-red-500 font-semibold">具体学生干部竞选的操作方法，先登社区内包含学生干部竞选演讲等各项1V1指导。</p>

        <h4>二、	兴趣社团</h4>
        <p>同学可以通过参加符合自己特长的社团，展现出自己的风采，在学校表现机会更多；另一方面如果你是一个内向的人，多参加一些演讲、辩论等有利于提升自己短板的社团。</p>
        <p>社团建议不要过多，社团一般都要交会费，社团报的多，不仅浪费钱还容易顾此失彼、耽误时间。</p>
        <p>社团类型多种多样，下面列举一些：</p>
        <h5>· 球类运动</h5>
        <ol class="list-decimal">
            <li>大学期间重视体育运动，不能沉迷手机;每个学生建议至少学会一项球类运动如足球、网球、篮球、排球、羽毛球、乒乓球等。
                </li>
            <li>体育运动也是大学非常重要的一项社交方式，不仅有利于强身健体，还能结交全校本科生、研究生等不同层次的朋友。
            </li>
        </ol>
        <h5>· 学工助理</h5>
        <ol class="list-decimal">
            <li>学生可在大学阶段参加学工助理工作。学工助理相对工作难度不是很大，主要帮助学校各个岗位老师完成一些辅助性工作。
                </li>
            <li>学工助理和学校老师、领导接触较多，在老师的指导下工作，能锻炼学生复杂事情处理能力，同时有综合素质分加分机会。
            </li>
        </ol>
        <h5>· 校园后勤</h5>
        <ol class="list-decimal">
            <li>对于有收入需求或者家庭条件一般的同学，可以参加学校的后勤助理岗位。主要包括校园环境维护、餐饮服务、宿舍管理、物资采购与设备维修等保障校园正常运转的事务。
                </li>
            <li>参加校园后勤助理工作能锻炼学生的实践能力、责任感，积累工作经验，提升沟通协作能力，对就业有积极帮助。
            </li>
        </ol>
        <h5>· 辩论赛</h5>
        <ol class="list-decimal">
            <li>辩论赛是首推的大学赛事，辩论赛是正反双方就特定辩题展开辩论的活动，通过立论、攻辩、自由辩论、总结陈词来阐述观点。不管是哪个专业都适合。辩论赛有校赛、省赛、国赛、国际赛事等。
                </li>
            <li>大学生在大学任何阶段都可参加辩论赛。大一积累经验，大二大三发挥优势，大四也能锻炼思维。参加辩论赛能提升学生的逻辑思维、语言表达和应变能力，这些能力在就业面试和工作沟通中很有帮助。
            </li>
        </ol>
        <h5>· 朗诵比赛</h5>
        <ol class="list-decimal">
            <li>有相关特长的学生尤其建议参加，不仅可锻炼胆量，更是一场语言艺术的竞技参与者以富有情感与表现力的朗诵，诠释经典或自创作品，借声音传递文字力量展现朗诵魅力与个人风采
                </li>
            <li>学生参加朗诵比赛可以提升综合素质、语言表达、自信心等能力。在评优或自招环节展现个人特长，这些能力在求职面试等环节发挥优势，利于就业。
            </li>
        </ol>
        <h5>· 校园歌手大赛</h5>
        <ol class="list-decimal">
            <li>校园歌手大赛是校内音乐盛事，活动影响力非常大，是众多学子展示自己非常好的场合!建议有此特长的学生务必参加。
                </li>
            <li>学生们登台竞技，用歌声展现才华与情感，评委打分评选，为热爱音乐者提供闪耀舞台与交流机会。校园歌手大赛可提升学生表现力和自信心。这些素质有助于在就业面试中更好地展示自我，增加竞争力。
            </li>
        </ol>
        <h5>· 英文演讲比赛</h5>
        <ol class="list-decimal">
            <li>高中英语有演讲比赛经验的，这个优势就非常大了。英文演讲比赛通常围绕特定主题，选手用英语进行演讲展示，比拼语言能力、内容深度、表达技巧等，旨在提升英语综合素养。
                </li>
            <li>参加英文演讲比赛不仅能提升学生英语表达与沟通能力、增强自信和应变力，如果获得比较好的奖项，在简历添亮点，利于拓宽就业渠道，增加竞争力。
            </li>
        </ol>

<!--        七、就业规划-->
        <h3 id="job-planning">七、就业规划</h3>

        <h4 id="job-retrieving">就业准备:</h4>
        <h5>（一）个人简历</h5>
        <p>个人简历是就业的敲门砖，想要拥有一份优质的简历，就需要我们大学四年在大学生活、大学学业、大学实践、就业准备上获得丰富的成果，这样才能获得各个大厂的青睐。因此，简历并不是到了大四求职季才开始撰写，而是从大一开始，就要用实际行动，来丰富自己简历里的内容了！</p>
        <p class="no-ind text-red-500 font-semibold">先登社区内提供就业训练营，给同学们详细指导简历撰写及相关技巧</p>

        <h5>（二）笔试筹备</h5>
        <p>我国目前所有体制内单位，基本都实行 网络申报——笔试——面试 的招考流程。而所有体制内单位笔试内容，也基本趋于统一，绝大部分招考通道，包括央企，部队文职，三支一扶，选调生，考公考编等，皆会统一考察【行政能力测验】这门笔试科目。</p>
        <p>该科目特点为不需要专业基础，没有技术难度壁垒，所有同学皆可上手学习，但学习量大。因此需要同学利用大四之前的3年时间里，提前将该科目学习完毕。</p>
        <p>部分体制内单位还会额外加试【公共基础知识】【申论】等笔试科目。也需要同学们提前筹备学习。</p>
        <p class="no-ind text-red-500 font-semibold">先登社区内提供全部行政能力测验，公共基础知识，申论的课程及题库等学习资源</p>

        <h5>（三）面试筹备</h5>
        <p>面试是求职的最后一个阶段，一般来说包括单面和群面两类模式。面试中着重考察同学的仪容形象气质，沟通表达，随机应变，抗压能力等等。面试官会根据简历撰写内容，有针对性的提问。大学生应该利用大四之前的3年，积极抓住各种可以锻炼个人上述能力的机会。尤其是社会实习实践等实际工作机会，才能得到真实的锻炼成长，并充满自信地应对将来的面试。</p>
        <p class="no-ind text-red-500 font-semibold">先登社区内提供就业训练营，给同学们详细指导面试及相关技巧</p>

        <h4>就业通道：</h4>
        <p class="font-semibold">当前就业环境竞争激烈，但依然有很多就业通道。除常规的校招之外，也有很多体制内单位招考应届毕业生，具体通道如下：</p>
        <jobChannelNode />
        <p class="no-ind text-red-500 font-semibold">先登社区内提供海量实时就业信息，包括95%以上同学无法接触到的央企招聘岗位信息。</p>
    </div>
</template>

<script setup lang="ts">
import {formatSex} from '@/models/account'
import type {PlanningReportData} from "@/api/request/service.ts";
import {computed, h, Fragment, ref, onMounted} from "vue";
// import {useProfileStore} from "@/stores/profile.ts";

// const profileStore = useProfileStore()

const props = defineProps<{
    reportData?: PlanningReportData,
    // isGraduateEligible: boolean
}>()

// 判断是否有选调资格
const isXuandiaoEligible = computed(() => {
    if (!props.reportData) {return false}
    return props.reportData.degree == 'BACHELOR' && (props.reportData.uniremark == null || props.reportData.uniremark == '')
})
// 就读建议分流
const bachelorStudySuggestion = computed(() => {
    if (!props.reportData) {return ""}
    const paraphs = props.reportData.genstudysuggestion.split("\n\n")
    const newParaphs = paraphs.slice(0, 2)
    newParaphs.push(props.reportData.core_course_learning)
    newParaphs.push(props.reportData.practical_skill_development)
    newParaphs.push(props.reportData.skill_expansion)
    newParaphs.push(paraphs[2])

    const hProps = {
        style: {
            width: '80%',
            marginTop: '1rem',
            marginInline: 'auto'
        }
    }
    const pProps = {
        style: {
            width: '75%',
            margin: 'auto',
            whiteSpace: 'pre-line',
            lineHeight: '2rem',
            textIndent: '2rem'
        }
    }
    return h('div', [
        h('h4', hProps, '· 本专业概述'),
        h('p', pProps, newParaphs[0]),
        h('h4', hProps,'· 本专业学业规划'),
        h('p', pProps, newParaphs[1]),
        h('h4', hProps,'· 实践能力培养'),
        h('p', pProps, newParaphs[2]),
        h('h4', hProps,'· 专业技能扩展'),
        h('p', pProps, newParaphs[3]),
        h('h4', hProps,'· 就业行业及岗位方向'),
        h('p', pProps, newParaphs[4]),
        h('h4', hProps,'· 职业发展建议'),
        h('p', pProps, newParaphs[5]),
    ])
})

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
    key: 'overall',
    href: '#overall',
    title: '6 综合事项',
  },
  {
    key: 'job-planning',
    href: '#job-planning',
    title: '7 就业',
  },

]

// const imgSource = [
//     "/images/planning-report/baoyan1.png",
//     "/images/planning-report/kaoyan1.png",
//     "/images/planning-report/job1.png",
//     "/images/planning-report/mbti.png",
// ]

// h5 - p structure
const chineseBrackets = [
    "（一）",
    "（二）",
    "（三）",
    "（四）",
    "（五）",
    "（六）",
    "（七）",
    "（八）",
    "（九）",
    "（十）",
]
// const jobChannelOrderMark = "chinese-bracket"
const jobChannelStructure = ref([
    {
        title: "央国企",
        contents: [
            "大型央国企基本只招聘应届生，且基本不做校园招聘，因此在学生中存在信息差，了解央国企招聘信息和渠道的人占比极低。成功入职央国企，可获得体制内编制身份。收入较高且稳定，无后顾之忧，福利众多，法定假日不缺席，平日工作不加班，生活幸福感获得感高，社会地位受人尊敬。另外，央国企的发展路径可深造为专家型岗位或管理型岗位（走从政路线）。你所学专业，可报考的目标央国企包括：国家电网，中国移动，中国石化，中国航空航天，中国兵器，保利集团，国家开发投资集团等242家涉及制造，金融，民生等不同产业领域的央企。"
        ]
    },
    {
        title: "部队文职",
        contents: [
            "部队各单位每年会招聘应届毕业生充入军队文职岗位，从事技术支持或行政后勤工作。待遇非常优厚，获得正式部队编制，可长期深耕走军队系统发展路线，职业身份高，无后顾之忧。部队文职不做校园招聘，因此在学生中存在信息差，了解相应招聘信息和渠道的人占比极低。可报考单位包括：国防大学，火箭军，武警部队，军委后勤保障部，军委科学技术委员会，战略支援部队等等众多单位。"
        ]
    },
    {
        title: "三支一扶",
        contents: [
            "三支一扶为支教，支医，支农。通过各省统一考试可获得录取名额。参加为期2年的基层服务工作。2年后，考核合格有机会直接获得入编机会。个别地区暂无入编机会的，亦可以被视同具有2年基层工作经验的人员，享受公务员和事业单位定向考录招聘的优惠政策。若继续升学，无论保研还是考研，则可以获得相应的政策优惠。"
        ]
    },
    {
        title: "公务员",
        contents: [
            "1.根据职位性质，公务员可以划分为多种类型，其中主要包括国考、省考/市考/区考、选调生考试、遴选以及聘任制公务员等五种。",
            "①国考：即中央、国家机关公务员考试，这是国家层面组织的公务员招录考试， 通常对考生的学历和专业有较高要求，考试内容全国统一，竞争激烈。国考招录的公务员主要服务于中央和国家机关，承担着国家层面的管理和服务工作。每年的10月中旬左右发布公告、开始报名，11月底或12月初进行笔试。",
            "②省考/市考/区考：也称为“省联考”，是地方各级党政机关等为招录机关工作人员而组织进行的各级地方性考试。考试内容与国考类似，但针对的是地方层面的管理和服务需求。省考/市考/区考招录的公务员主要服务于地方党政机关，是地方管理和服务的重要力量。一般在每年的上半年进行，多数省份会参加春季联考，通常在3月左右发布公告、开始报名，4月进行笔试。",
            "③选调生考试：这是各省党委组织部门有计划地从高等院校选调品学兼优的应届大学毕业生到基层工作的一种方式。选调生作为党政领导干部后备人选和县级以上党政机关高素质的工作人员人选，将接受重点培养，并有望成为未来领导层的重要成员。选调生更加严格，政治面貌一般为预备党员或党员，同时兼具三好学生或者优秀学生干部身份，年龄18-25岁，如果是研究生学历，年龄可以放宽到30岁。",
            "④遴选：是公务员队伍中的一种跨政府层级、工作部门、地区的竞争性选拔方式。遴选主要针对在职公务员，旨在通过竞争性的选拔机制，实现公务员的晋升和转任， 促进公务员队伍的优化和流动。",
            "⑤聘任制公务员：这是根据工作需要，通过合同聘用的方式建立的劳动关系。聘任制公务员通常适用于专业性强或辅助性职位，如法律顾问、技术专家等。这种灵活的用人方式有助于吸引和留住专业人才，提高政府工作的专业性和效率。",
            "2.公务员考试内容：行政职业能力测验（行测）、申论、专业科目笔试（部分职位需要）、结构化面试、无领导小组讨论、结构化小组面试",
            "3.公务员越来越多的岗位要求研究生报考，限制条件也越来越多，有考公务员想法的同学务必提前做好规划，提前了解自己想要报考岗位的学历、专业要求。"
        ]
    },
    {
        "title": "考编",
        "contents": [
            "考编的种类多样，包括公务员考试（如国考、省考）、事业单位考试（如教育、科研、卫生等领域）以及军队文职人员考试等。公务员考试考取的是行政编制，事业单位考试考取的是事业编制，而军队文职人员考试则是军队编制。",
            "考编的优势在于工作稳定，一旦考上，通常不用担心失业问题，且社会地位较高。然而，考编的劣势在于薪资和晋升渠道相对固定，竞争激烈，需要付出较多努力才能脱颖而出。",
            "考编的要求也较为严格，包括国籍、年龄、学历、专业等条件，某些岗位还需要特定的资格证书（如教师资格证或医疗资质）。",
            "如果参加教师编制考试，大三下学期可以开始报名教师资格证考试，这是考编的前提条件。大四上学期可以开始关注教师编考试的相关信息和准备。毕业后可以参加各地的教师招聘考试，通常需要在毕业后才能以应届毕业生身份报考。大多数省份的教师编制考试集中在上半年，通常在3月至6月之间进行。下半年考试一般在8月至10月之间进行。",
            "具体考试类型和时间如下：",
            "①教师编考试：这是每年最为正式且全面的教师编制考试，通常在上半年进行，是检验专业知识和教学能力的重要机会。",
            "②事业编D类考试：特别针对中小学教师岗位，通常在4月进行。",
            "③特岗教师考试：一般在6月至7月进行，服务期为3年，期满后可转为编制。",
            "④三支一扶：类似特岗教师，服务期为2年，期满后可转为编制。",
            "⑤校招：主要针对应届生，通常在3月至5月和9月至11月进行，部分岗位直接提供编制。",
            "如果参加事业单位考试，大四下学期可以开始关注事业单位考试的相关信息和准备。毕业后参加各地的招聘考试，考试时间集中在3-5月和8-10月。"
        ]
    },
    {
        "title": "高校教师",
        "contents": [
            "很多学生想毕业后到大学任教，大学校园确实是一个让人怀念的地方，但是毕业后想去大学任教，目前基本上都是要求博士学历，部分岗位要求硕士及以上学历。",
            "进入高校任教，读研、读博基本上是绕不开的路径。"
        ]
    },
    {
        "title": "政法干警",
        "contents": [
            "政法干警招录的对象是应届毕业生，考生通过考试后需到报考院校学习两年，一年理论课和一年实践课，学习期间每月有一定的生活补助，免交学费。毕业后，经双重考核合格后，回原报考单位签订工作协议，具备政法干警公务员的身份。",
            "政法干警毕业后，分配到相应的岗位任职，包括法院、检察院干部和法警、公安民警、司法所干部及狱警等岗位。国家统一发放被褥和服装，每月有生活补助，毕业即获得公务员编制并到报考岗位工作。",
            "政法干警考试包括行政职业能力测验和申论考试。报考专科的考生需参加文化综合（历史、地理、政治）的考试；本科层次考民法学；报考法律硕士专业学位研究生的考生需参加专业综合（刑法学、民法学）、专业综合（法理学、中国宪法学、中国法制史）的考试。"
        ]
    },
    {
        "title": "村官",
        "contents": [
            "大学生村官是指到农村（含社区）担任村党支部书记、村委会主任助理或其他村'两委'职务的具有大专及以上学历的应届或往届大学毕业生。大学生村官工作是国家开展的选派项目，岗位性质为'村级组织特设岗位'，非公务员身份。其工作、生活补助和享受的保障待遇由中央和地方财政共同承担。",
            "大学生村官的报名条件一般包括30周岁以下、应届全日制普通高校本科以上学历的毕业生，或有相关经验的优秀毕业生。报名方式主要有两种：通过学校就业部门参与定向招录，或关注各省市发布的招聘公告进行网上报名。",
            "大学生村官考试的内容主要包括笔试和面试两部分。笔试部分通常包括行政职业能力测验和申论。面试部分主要测评考生的综合素质，包括自我介绍、政策常识、综合素质等。自我介绍涉及个人基本信息、家庭背景和教育经历等；政策常识考察考生对国家、省、市的最新政策了解程度；综合素质则涉及考生的适应能力、组织能力和沟通能力等。"
        ]
    },
    {
        "title": "大学行政",
        "contents": [
            "毕业留在高校做行政人员是很多学生想要的选择，大学也为很多优秀的应届本科生设置了一些岗位，如辅导员、团委工作等。",
            "本科生留在大学是不容易的，需要你提前做好规划，在学生会、社团表现、学工助理岗位等表现突出，本科期间能够入党、没有挂科表现等，每个学校的要求也有所不同，大家根据需求可在大一就询问辅导员本校政策，按照学校要求一步步发展。",
            "如果单纯做辅导员，发展还是相对受限的，即便留校了还是要继续考在职研究生、博士生，往讲师、研究员、副教授等方向发展相对空间较大。"
        ]
    },
])


// const styles = useCssModule() // 获取模块作用域样式
const jobChannelNode = computed(() => {
    return h(Fragment, jobChannelStructure.value.map((item) => {
        console.log(chineseBrackets[jobChannelStructure.value.indexOf(item)])
        const chineseBullet = chineseBrackets[jobChannelStructure.value.indexOf(item)]
        return [
            h("h5", { style: {
                    fontSize: "14px",
                    marginTop: "1rem",
                    width: "80%",
                    marginInline: "auto"
                } },  chineseBullet + item.title),
            item.contents.map((content) => {
                return h("p", {style: {
                        width: "75%",
                        margin: "auto",
                        whiteSpace: "pre-line",
                        lineHeight: "2rem",
                        textIndent: "2rem"
                    }}, content)
            })
        ]
    }))
})

onMounted(() => {
    console.log("isXuandiaoEligible" , isXuandiaoEligible.value)
    if (isXuandiaoEligible.value) {
        jobChannelStructure.value.splice(2, 0, {
            title: "选调",
            contents: [
                "选调生是党中央及各省党委组织部门有计划地从高等院校选调品学兼优的应届大学本科及其以上毕业生到基层工作，作为党政领导干部后备人选和县级以上党政机关高素质的工作人员人选进行重点培养的人才招聘渠道。",
                "作为预备干部，选调生职业起点远高于普通公务员，晋升发展也最快，是从政路线最优发展方向。"
            ]
        })
    }
    console.log(jobChannelStructure.value)
})
</script>

<style scoped>
/* table, td {
    border: 1px solid;
} */

#cover-page {
    -webkit-print-color-adjust: exact;
    background-image: url("/images/planning-report/xiandeng-planning-bg.png");
    background-size: cover;
    margin-inline: auto;
    aspect-ratio: 0.6;
}
td {
    background-color: #c9ecff;
}
table {
    border-collapse: separate;
    width: 70%;
}

.report > p {
    width: 75%;
    margin: auto;
    white-space: pre-line;
    line-height: 2rem;
    text-indent: 2rem;


}

.report > p.no-ind {
    text-indent: 0;
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
    width: 90%;
    margin-inline: auto;
}

.report > h4 {
    font-size: 16px;
    margin-top: 1rem;
    width: 85%;
    margin-inline: auto;
}

.report > h5 {
    font-size: 15px;
    margin-top: 1rem;
    width: 80%;
    margin-inline: auto;
}

.report > ul {
    margin-inline: auto;
    line-height: 2rem;
    width: 75%;

}

.report > ol {
    margin-inline: auto;
    width: 65%;
    list-style-type: decimal;
    line-height: 2rem;
}

span.kw {
    color: red;
    font-weight: 600;
}

.baoyan-schedule-table th {
    padding-top: 8px;
    padding-bottom: 8px;
}
.baoyan-schedule-table td {
    padding-top: 8px;
    padding-bottom: 8px;
}
</style>
