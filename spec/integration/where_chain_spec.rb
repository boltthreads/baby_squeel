require 'spec_helper'

describe BabySqueel::ActiveRecord::WhereChain do
  describe '#has' do
    it 'wheres on an attribute' do
      relation = Post.where.has {
        title == 'OJ Simpson'
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        WHERE "posts"."title" = 'OJ Simpson'
      EOSQL
    end

    it 'accepts nil' do
      relation = Post.where.has { nil }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
      EOSQL
    end

    it 'wheres on associations' do
      relation = Post.joins(:author).where.has {
        author.name == 'Yo Gotti'
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
        WHERE "authors"."name" = 'Yo Gotti'
      EOSQL
    end

    it 'wheres using functions' do
      relation = Post.joins(:author).where.has {
        coalesce(title, author.name) == 'meatloaf'
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
        WHERE coalesce("posts"."title", "authors"."name") = 'meatloaf'
      EOSQL
    end

    it 'wheres using operations' do
      relation = Post.where.has { (id + 1) == 2 }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        WHERE ("posts"."id" + 1) = 2
      EOSQL
    end

    it 'wheres using complex conditions' do
      relation = Post.joins(:author).where.has {
        (title =~ 'Simp%').or(author.name == 'meatloaf')
      }

      if ActiveRecord::VERSION::STRING < '4.2.0'
        expect(relation).to produce_sql(<<-EOSQL)
          SELECT "posts".* FROM "posts"
          INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
          WHERE (("posts"."title" LIKE 'Simp%' OR "authors"."name" = 'meatloaf'))
        EOSQL
      else
        expect(relation).to produce_sql(<<-EOSQL)
          SELECT "posts".* FROM "posts"
          INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
          WHERE ("posts"."title" LIKE 'Simp%' OR "authors"."name" = 'meatloaf')
        EOSQL
      end
    end

    it 'wheres on associations' do
      relation = Post.joins(author: :comments).where.has {
        author.comments.id > 0
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
        INNER JOIN "comments" ON "comments"."author_id" = "authors"."id"
        WHERE ("comments"."id" > 0)
      EOSQL
    end

    it 'wheres on an aliased association' do
      relation = Post.joins(author: :posts).where.has {
        author.posts.id > 0
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
        INNER JOIN "posts" "posts_authors" ON "posts_authors"."author_id" = "authors"."id"
        WHERE ("posts_authors"."id" > 0)
      EOSQL
    end

    it 'wheres on an aliased association with through' do
      relation = Post.joins(:comments, :author_comments).where.has {
        author_comments.id > 0
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        INNER JOIN "comments" ON "comments"."post_id" = "posts"."id"
        INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
        INNER JOIN "comments" "author_comments_posts" ON "author_comments_posts"."author_id" = "authors"."id"
        WHERE ("author_comments_posts"."id" > 0)
      EOSQL
    end

    it 'wheres on polymorphic associations' do
      relation = Picture.joining { imageable.of(Post) }.where.has {
        imageable.of(Post).title =~ 'meatloaf'
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "pictures".* FROM "pictures"
        INNER JOIN "posts" ON "posts"."id" = "pictures"."imageable_id" AND "pictures"."imageable_type" = 'Post'
        WHERE ("posts"."title" LIKE 'meatloaf')
      EOSQL
    end

    it 'wheres on polymorphic associations outer join' do
      relation = Picture.joining { imageable.of(Post).outer }.where.has {
        imageable.of(Post).title =~ 'meatloaf'
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "pictures".* FROM "pictures"
        LEFT OUTER JOIN "posts" ON "posts"."id" = "pictures"."imageable_id" AND "pictures"."imageable_type" = 'Post'
        WHERE ("posts"."title" LIKE 'meatloaf')
      EOSQL
    end

    it 'wheres and correctly aliases' do
      relation = Post.joining { author.comments }
                     .where.has { author.comments.id.in [1, 2] }
                     .where.has { author.name == 'Joe' }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
        INNER JOIN "comments" ON "comments"."author_id" = "authors"."id"
        WHERE "comments"."id" IN (1, 2) AND "authors"."name" = 'Joe'
      EOSQL
    end

    it 'wheres on an alias with outer join' do
      relation = Post.joining { author.comments.outer }
                     .where.has { author.comments.id.in [1, 2] }
                     .where.has { author.name == 'Joe' }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
        LEFT OUTER JOIN "comments" ON "comments"."author_id" = "authors"."id"
        WHERE "comments"."id" IN (1, 2) AND "authors"."name" = 'Joe'
      EOSQL
    end

    it 'wheres on an alias with a function' do
      relation = Post.joins(author: :posts).where.has {
        coalesce(author.posts.id, 1) > 0
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
        INNER JOIN "posts" "posts_authors" ON "posts_authors"."author_id" = "authors"."id"
        WHERE (coalesce("posts_authors"."id", 1) > 0)
      EOSQL
    end

    it 'wheres with a subquery' do
      relation = Post.joins(:author).where.has {
        author.id.in Author.selecting { id }.limit(3)
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
        WHERE "authors"."id" IN (SELECT "authors"."id" FROM "authors" LIMIT 3)
      EOSQL
    end

    it 'wheres using a simple table' do
      simple = if Arel::VERSION > '7.0.0'
                 BabySqueel[:authors, type_caster: Author.type_caster]
               else
                 BabySqueel[:authors]
               end

      relation = Post.joins(:author).where.has {
        simple.name == 'Yo Gotti'
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
        WHERE "authors"."name" = 'Yo Gotti'
      EOSQL
    end

    it 'builds an exists query' do
      relation = Post.where.has {
        exists Post.where.has { author_id == 1 }
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        WHERE (
          EXISTS(
            SELECT "posts".* FROM "posts"
            WHERE "posts"."author_id" = 1
          )
        )
      EOSQL
    end

    it 'builds a not exists query' do
      relation = Post.where.has {
        not_exists Post.where.has { author_id == 1 }
      }

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        WHERE (
          NOT EXISTS(
            SELECT "posts".* FROM "posts"
            WHERE "posts"."author_id" = 1
          )
        )
      EOSQL
    end

    it 'wheres an association using #==' do
      if ActiveRecord::VERSION::MAJOR < 5
        skip "This isn't supported in ActiveRecord 4"
      end

      author = Author.new(id: 42)
      relation = Post.where.has do |post|
        post.author == author
      end

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        WHERE ("posts"."author_id" = 42)
      EOSQL
    end

    it 'wheres an association using #!=' do
      if ActiveRecord::VERSION::MAJOR < 5
        skip "This isn't supported in ActiveRecord 4"
      end

      author = Author.new(id: 42)
      relation = Post.where.has do |post|
        post.author != author
      end

      expect(relation).to produce_sql(<<-EOSQL)
        SELECT "posts".* FROM "posts"
        WHERE (("posts"."author_id" != 42))
      EOSQL
    end
  end

  describe '#where_values_hash' do
    it 'returns the same hash that Rails normally would' do
      squeel = Author.where.has{id == 123}
      rails = Author.where(id: 123)
      expect(squeel.where_values_hash).to eq(rails.where_values_hash)
    end
  end

  describe "joining tables with matching attributes"  do
    context "where the parent table column_type is float and the child table column_type is string" do
      context "wheres based on the child model's attribute" do
        it 'uses the column_type of the child' do
          relation = Station.joins(:shows).where.has { shows.frequency == 'daily' }

          expect(relation).to produce_sql(<<-EOSQL)
            SELECT "stations".* FROM "stations"
            INNER JOIN "shows" ON "stations"."id" = "shows"."station_id"
            WHERE ("shows"."frequency" = "daily")
          EOSQL
        end
      end

      context "wheres based on the parent model's attribute" do
        it 'uses the column_type of the parent' do
          relation = Show.joins(:station).where.has { station.frequency == 4.2 }

          expect(relation).to produce_sql(<<-EOSQL)
            SELECT "shows".* FROM "shows"
            INNER JOIN "stations" ON "stations"."id" = "shows"."station_id"
            WHERE "stations"."frequency" = 4.2
          EOSQL
        end
      end
    end
  end

end
