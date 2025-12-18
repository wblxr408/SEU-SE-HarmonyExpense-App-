/**
 * 数据模型定义
 * 用于 MockData 的示例数据结构
 */

/**
 * 分类ID枚举
 */
export enum CategoryId {
  Vegetable = 1,
  Fruit = 2,
  Nut = 3,
  Seafood = 4,
  Dessert = 5
}

/**
 * 用餐时间ID枚举
 */
export enum MealTimeId {
  Breakfast = 1,
  Lunch = 2,
  Dinner = 3,
  Supper = 4
}

/**
 * 食物信息类
 */
export class FoodInfo {
  id: number;
  name: string;
  nameResource: Resource;
  imageResource: Resource;
  categoryId: CategoryId = CategoryId.Vegetable;
  calories: number = 0;
  protein: number = 0;
  fat: number = 0;
  carbohydrates: number = 0;
  vitaminC: number = 0;

  constructor(id: number, name: string, nameResource: Resource, imageResource: Resource) {
    this.id = id;
    this.name = name;
    this.nameResource = nameResource;
    this.imageResource = imageResource;
  }
}

/**
 * 用餐时间类
 */
export class MealTime {
  id: MealTimeId;

  constructor(id: MealTimeId) {
    this.id = id;
  }
}

/**
 * 饮食记录类
 */
export class DietRecord {
  id: number;
  foodId: number;
  mealTime: MealTime;
  amount: number;

  constructor(id: number, foodId: number, mealTime: MealTime, amount: number) {
    this.id = id;
    this.foodId = foodId;
    this.mealTime = mealTime;
    this.amount = amount;
  }
}
