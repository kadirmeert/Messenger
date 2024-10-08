/*************************************************************************
 *
 * Copyright 2016 Realm Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 **************************************************************************/

#ifndef REALM_SPEC_HPP
#define REALM_SPEC_HPP

#include <realm/util/features.h>
#include <realm/array.hpp>
#include <realm/array_string_short.hpp>
#include <realm/data_type.hpp>
#include <realm/column_type.hpp>
#include <realm/keys.hpp>

namespace realm {

class Table;
class Group;

class Spec {
public:
    ~Spec() noexcept;

    Allocator& get_alloc() const noexcept;

    // insert column at index
    void insert_column(size_t column_ndx, ColKey column_key, ColumnType type, StringData name,
                       int attr = col_attr_None);
    ColKey get_key(size_t column_ndx) const;
    void rename_column(size_t column_ndx, StringData new_name);

    /// Erase the column at the specified index.
    ///
    /// This function is guaranteed to *never* throw if the spec is
    /// used in a non-transactional context, or if the spec has
    /// already been successfully modified within the current write
    /// transaction.
    void erase_column(size_t column_ndx);

    // Column info
    size_t get_column_count() const noexcept;
    size_t get_public_column_count() const noexcept;
    ColumnType get_column_type(size_t column_ndx) const noexcept;
    StringData get_column_name(size_t column_ndx) const noexcept;

    /// Returns size_t(-1) if the specified column is not found.
    size_t get_column_index(StringData name) const noexcept;

    // Column Attributes
    ColumnAttrMask get_column_attr(size_t column_ndx) const noexcept;
    void set_dictionary_key_type(size_t column_ndx, DataType key_type);
    DataType get_dictionary_key_type(size_t column_ndx) const;

    // Auto Enumerated string columns
    void upgrade_string_to_enum(size_t column_ndx, ref_type keys_ref);
    size_t _get_enumkeys_ndx(size_t column_ndx) const noexcept;
    bool is_string_enum_type(size_t column_ndx) const noexcept;
    ref_type get_enumkeys_ref(size_t column_ndx, ArrayParent*& keys_parent) noexcept;

    //@{
    /// Compare two table specs for equality.
    bool operator==(const Spec&) const noexcept;
    bool operator!=(const Spec&) const noexcept;
    //@}

    void detach() noexcept;
    void destroy() noexcept;

    size_t get_ndx_in_parent() const noexcept;

    void verify() const;

private:
    // Underlying array structure.
    //
    static constexpr size_t s_types_ndx = 0;
    static constexpr size_t s_names_ndx = 1;
    static constexpr size_t s_attributes_ndx = 2;
    static constexpr size_t s_vacant_1 = 3;
    static constexpr size_t s_enum_keys_ndx = 4;
    static constexpr size_t s_col_keys_ndx = 5;
    static constexpr size_t s_spec_max_size = 6;

    Array m_top;
    Array m_types;            // 1st slot in m_top
    ArrayStringShort m_names; // 2nd slot in m_top
    Array m_attr;             // 3rd slot in m_top
                              // 4th slot in m_top not cached
    Array m_enumkeys;         // 5th slot in m_top
    Array m_keys;             // 6th slot in m_top
    size_t m_num_public_columns = 0;

    Spec(Allocator&) noexcept; // Unattached

    void init(ref_type) noexcept;
    void init(MemRef) noexcept;

    void init_from_parent() noexcept;

    ref_type get_ref() const noexcept;

    void set_parent(ArrayParent*, size_t ndx_in_parent) noexcept;

    void set_column_attr(size_t column_ndx, ColumnAttrMask attr);

    // Migration
    bool migrate_column_keys();

    /// Construct an empty spec and return just the reference to the
    /// underlying memory.
    static MemRef create_empty_spec(Allocator&);

    friend class Group;
    friend class Table;
};

// Implementation:

inline Allocator& Spec::get_alloc() const noexcept
{
    return m_top.get_alloc();
}

// Uninitialized Spec (call init() to init)
inline Spec::Spec(Allocator& alloc) noexcept
    : m_top(alloc)
    , m_types(alloc)
    , m_names(alloc)
    , m_attr(alloc)
    , m_enumkeys(alloc)
    , m_keys(alloc)
{
    m_types.set_parent(&m_top, s_types_ndx);
    m_names.set_parent(&m_top, s_names_ndx);
    m_attr.set_parent(&m_top, s_attributes_ndx);
    m_enumkeys.set_parent(&m_top, s_enum_keys_ndx);
    m_keys.set_parent(&m_top, s_col_keys_ndx);
}

inline void Spec::init_from_parent() noexcept
{
    init(m_top.get_ref_from_parent());
}

inline void Spec::destroy() noexcept
{
    m_top.destroy_deep();
}

inline size_t Spec::get_ndx_in_parent() const noexcept
{
    return m_top.get_ndx_in_parent();
}

inline ref_type Spec::get_ref() const noexcept
{
    return m_top.get_ref();
}

inline void Spec::set_parent(ArrayParent* parent, size_t ndx_in_parent) noexcept
{
    m_top.set_parent(parent, ndx_in_parent);
}

inline void Spec::rename_column(size_t column_ndx, StringData new_name)
{
    REALM_ASSERT(column_ndx < m_types.size());
    m_names.set(column_ndx, new_name);
}

inline size_t Spec::get_column_count() const noexcept
{
    // This is the total count of columns, including backlinks (not public)
    return m_types.size();
}

inline size_t Spec::get_public_column_count() const noexcept
{
    return m_num_public_columns;
}

inline ColumnType Spec::get_column_type(size_t ndx) const noexcept
{
    REALM_ASSERT(ndx < get_column_count());
    return ColumnType(int(m_types.get(ndx) & 0xFFFF));
}

inline ColumnAttrMask Spec::get_column_attr(size_t ndx) const noexcept
{
    REALM_ASSERT(ndx < get_column_count());
    return ColumnAttrMask(m_attr.get(ndx));
}

inline void Spec::set_dictionary_key_type(size_t ndx, DataType key_type)
{
    auto type = m_types.get(ndx);
    m_types.set(ndx, (type & 0xFFFF) + (int64_t(key_type) << 16));
}

inline DataType Spec::get_dictionary_key_type(size_t ndx) const
{
    REALM_ASSERT(ndx < get_column_count());
    return DataType(int(m_types.get(ndx) >> 16));
}

inline void Spec::set_column_attr(size_t column_ndx, ColumnAttrMask attr)
{
    REALM_ASSERT(column_ndx < get_column_count());

    // At this point we only allow one attr at a time
    // so setting it will overwrite existing. In the future
    // we will allow combinations.
    m_attr.set(column_ndx, attr.m_value);
}

inline StringData Spec::get_column_name(size_t ndx) const noexcept
{
    return m_names.get(ndx);
}

inline size_t Spec::get_column_index(StringData name) const noexcept
{
    return m_names.find_first(name);
}

inline bool Spec::operator!=(const Spec& s) const noexcept
{
    return !(*this == s);
}

} // namespace realm

#endif // REALM_SPEC_HPP
